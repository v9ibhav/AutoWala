<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rider;
use App\Models\Ride;
use App\Models\Vehicle;
use App\Models\Route as RiderRoute;
use App\Services\Firebase\RealtimeService;
use App\Services\Ride\RideDiscoveryService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class RiderController extends Controller
{
    protected RealtimeService $realtimeService;
    protected RideDiscoveryService $rideDiscoveryService;

    public function __construct(
        RealtimeService $realtimeService,
        RideDiscoveryService $rideDiscoveryService
    ) {
        $this->realtimeService = $realtimeService;
        $this->rideDiscoveryService = $rideDiscoveryService;
    }

    /**
     * Complete rider registration with vehicle details
     */
    public function register(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|min:2|max:100',
                'email' => 'nullable|email|unique:riders,email',
                'date_of_birth' => 'nullable|date|before:today',
                'address' => 'required|string|max:255',
                'city' => 'required|string|max:100',
                'state' => 'required|string|max:100',
                'pincode' => 'required|string|size:6',
                'emergency_contact_name' => 'required|string|max:100',
                'emergency_contact_phone' => 'required|string|size:10',
                'years_experience' => 'required|integer|min:0|max:50',
                'license_number' => 'required|string|unique:riders,license_number',
                'license_expiry' => 'required|date|after:today',
                'vehicle_registration_number' => 'required|string|unique:vehicles,registration_number',
                'vehicle_model' => 'required|string|max:100',
                'vehicle_color' => 'required|string|max:50',
                'vehicle_year' => 'required|integer|min:1990|max:' . (date('Y') + 1),
                'vehicle_capacity' => 'required|integer|min:1|max:6',
                'insurance_number' => 'required|string',
                'insurance_expiry' => 'required|date|after:today',
                'accepts_digital_payment' => 'boolean'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid registration data',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Check if rider profile already exists for this user
            $existingRider = Rider::where('phone', auth()->user()->phone)->first();
            if ($existingRider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider profile already exists for this phone number'
                ], 400);
            }

            // Create rider profile
            $rider = Rider::create([
                'phone' => auth()->user()->phone,
                'name' => $request->name,
                'email' => $request->email,
                'date_of_birth' => $request->date_of_birth,
                'address' => $request->address,
                'city' => $request->city,
                'state' => $request->state,
                'pincode' => $request->pincode,
                'emergency_contact_name' => $request->emergency_contact_name,
                'emergency_contact_phone' => $request->emergency_contact_phone,
                'years_experience' => $request->years_experience,
                'license_number' => $request->license_number,
                'license_expiry' => $request->license_expiry,
                'insurance_number' => $request->insurance_number,
                'insurance_expiry' => $request->insurance_expiry,
                'accepts_digital_payment' => $request->accepts_digital_payment ?? false,
                'registration_status' => 'pending_verification',
                'kyc_verified' => false,
                'is_online' => false,
                'accepts_rides' => false,
                'overall_rating' => 5.0,
                'total_rides' => 0,
            ]);

            // Create vehicle record
            Vehicle::create([
                'rider_id' => $rider->id,
                'registration_number' => $request->vehicle_registration_number,
                'model' => $request->vehicle_model,
                'color' => $request->vehicle_color,
                'year' => $request->vehicle_year,
                'capacity' => $request->vehicle_capacity,
                'insurance_number' => $request->insurance_number,
                'insurance_expiry' => $request->insurance_expiry,
                'verification_status' => 'pending'
            ]);

            Log::info('Rider registration completed', [
                'rider_id' => $rider->id,
                'phone' => $rider->phone,
                'vehicle' => $request->vehicle_registration_number
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Registration completed successfully! Your documents are under verification.',
                'data' => [
                    'rider_id' => $rider->id,
                    'registration_status' => 'pending_verification',
                    'next_steps' => [
                        'Upload required documents for KYC verification',
                        'Wait for admin approval',
                        'Complete profile setup'
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Rider registration failed', [
                'phone' => auth()->user()->phone,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Registration failed',
                'error' => app()->environment('local') ? $e->getMessage() : null
            ], 500);
        }
    }

    /**
     * Get rider profile information
     */
    public function getProfile(): JsonResponse
    {
        try {
            $rider = Rider::with(['vehicle', 'routes'])
                ->where('phone', auth()->user()->phone)
                ->first();

            if (!$rider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider profile not found'
                ], 404);
            }

            return response()->json([
                'status' => 'success',
                'data' => [
                    'id' => $rider->id,
                    'name' => $rider->name,
                    'phone' => $rider->phone,
                    'email' => $rider->email,
                    'profile_photo' => $rider->profile_photo,
                    'registration_status' => $rider->registration_status,
                    'kyc_verified' => $rider->kyc_verified,
                    'years_experience' => $rider->years_experience,
                    'overall_rating' => $rider->overall_rating,
                    'total_rides' => $rider->total_rides,
                    'is_online' => $rider->is_online,
                    'accepts_rides' => $rider->accepts_rides,
                    'vehicle' => $rider->vehicle ? [
                        'registration_number' => $rider->vehicle->registration_number,
                        'model' => $rider->vehicle->model,
                        'color' => $rider->vehicle->color,
                        'capacity' => $rider->vehicle->capacity,
                        'verification_status' => $rider->vehicle->verification_status
                    ] : null,
                    'routes_count' => $rider->routes->count(),
                    'earnings' => [
                        'today' => 0, // Implement earnings calculation
                        'this_week' => 0,
                        'this_month' => 0
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get rider profile', [
                'phone' => auth()->user()->phone,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to fetch profile'
            ], 500);
        }
    }

    /**
     * Go online and start accepting rides
     */
    public function goOnline(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'heading' => 'nullable|numeric|between:0,360'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid location data',
                    'errors' => $validator->errors()
                ], 422);
            }

            $rider = Rider::where('phone', auth()->user()->phone)->first();

            if (!$rider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider profile not found'
                ], 404);
            }

            if (!$rider->kyc_verified) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'KYC verification required to go online'
                ], 403);
            }

            // Check for vehicle insurance expiry
            if ($rider->vehicle && $rider->vehicle->insurance_expiry < now()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Vehicle insurance expired. Please renew to go online.'
                ], 403);
            }

            // Update rider status and location
            $rider->update([
                'is_online' => true,
                'accepts_rides' => true,
                'current_latitude' => $request->latitude,
                'current_longitude' => $request->longitude,
                'current_heading' => $request->heading,
                'last_location_update' => now(),
                'went_online_at' => now()
            ]);

            // Start broadcasting location to Firebase
            $this->realtimeService->startLocationBroadcast($rider->id, [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'heading' => $request->heading,
                'status' => 'online',
                'timestamp' => now()->timestamp
            ]);

            Log::info('Rider went online', [
                'rider_id' => $rider->id,
                'location' => [$request->latitude, $request->longitude]
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'You are now online and accepting rides!',
                'data' => [
                    'is_online' => true,
                    'started_at' => now()->toISOString(),
                    'location' => [
                        'latitude' => $request->latitude,
                        'longitude' => $request->longitude
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to go online', [
                'phone' => auth()->user()->phone,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to go online'
            ], 500);
        }
    }

    /**
     * Go offline and stop accepting rides
     */
    public function goOffline(): JsonResponse
    {
        try {
            $rider = Rider::where('phone', auth()->user()->phone)->first();

            if (!$rider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider profile not found'
                ], 404);
            }

            // Check for active rides
            $activeRides = Ride::where('rider_id', $rider->id)
                ->whereIn('status', ['accepted', 'in_transit'])
                ->count();

            if ($activeRides > 0) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Cannot go offline with active rides. Complete current trips first.'
                ], 400);
            }

            // Calculate session duration and earnings
            $sessionDuration = $rider->went_online_at ? now()->diffInMinutes($rider->went_online_at) : 0;

            $rider->update([
                'is_online' => false,
                'accepts_rides' => false,
                'went_offline_at' => now()
            ]);

            // Stop broadcasting location
            $this->realtimeService->stopLocationBroadcast($rider->id);

            Log::info('Rider went offline', [
                'rider_id' => $rider->id,
                'session_duration_minutes' => $sessionDuration
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'You are now offline',
                'data' => [
                    'is_online' => false,
                    'session_duration_minutes' => $sessionDuration,
                    'ended_at' => now()->toISOString()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to go offline', [
                'phone' => auth()->user()->phone,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to go offline'
            ], 500);
        }
    }

    /**
     * Update rider's current location (high frequency)
     */
    public function updateLocation(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'heading' => 'nullable|numeric|between:0,360',
                'speed' => 'nullable|numeric|min:0|max:200', // km/h
                'accuracy' => 'nullable|numeric|min:0|max:1000' // meters
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid location data',
                    'errors' => $validator->errors()
                ], 422);
            }

            $rider = Rider::where('phone', auth()->user()->phone)->first();

            if (!$rider || !$rider->is_online) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider not found or not online'
                ], 404);
            }

            // Update database location
            $rider->update([
                'current_latitude' => $request->latitude,
                'current_longitude' => $request->longitude,
                'current_heading' => $request->heading,
                'current_speed' => $request->speed,
                'location_accuracy' => $request->accuracy,
                'last_location_update' => now()
            ]);

            // Update Firebase real-time location
            $locationData = [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'heading' => $request->heading,
                'speed' => $request->speed,
                'accuracy' => $request->accuracy,
                'timestamp' => now()->timestamp
            ];

            $this->realtimeService->updateRiderLocation($rider->id, $locationData);

            return response()->json([
                'status' => 'success',
                'message' => 'Location updated'
            ]);

        } catch (\Exception $e) {
            Log::error('Location update failed', [
                'phone' => auth()->user()->phone,
                'location' => $request->only(['latitude', 'longitude']),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Location update failed'
            ], 500);
        }
    }

    /**
     * Accept a ride request
     */
    public function acceptRide(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'ride_id' => 'required|exists:rides,id'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid ride ID',
                    'errors' => $validator->errors()
                ], 422);
            }

            $rider = Rider::where('phone', auth()->user()->phone)->first();

            if (!$rider || !$rider->is_online) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'You must be online to accept rides'
                ], 400);
            }

            $ride = Ride::where('id', $request->ride_id)
                ->where('rider_id', $rider->id)
                ->where('status', 'pending')
                ->first();

            if (!$ride) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride not found or already processed'
                ], 404);
            }

            // Update ride status
            $success = $this->rideDiscoveryService->updateRideStatus($ride->id, 'accepted');

            if (!$success) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Failed to accept ride'
                ], 500);
            }

            // Notify user via Firebase
            $this->realtimeService->notifyRideAccepted($ride->user_id, $ride);

            Log::info('Ride accepted', [
                'ride_id' => $ride->id,
                'rider_id' => $rider->id,
                'user_id' => $ride->user_id
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Ride accepted successfully!',
                'data' => [
                    'ride_id' => $ride->id,
                    'status' => 'accepted',
                    'pickup_address' => $ride->pickup_address,
                    'destination_address' => $ride->destination_address,
                    'estimated_fare' => $ride->estimated_fare,
                    'user' => [
                        'name' => $ride->user->name,
                        'phone' => $ride->user->phone
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Ride acceptance failed', [
                'phone' => auth()->user()->phone,
                'ride_id' => $request->ride_id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to accept ride'
            ], 500);
        }
    }

    /**
     * Complete a ride
     */
    public function completeRide(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'ride_id' => 'required|exists:rides,id',
                'final_fare' => 'nullable|numeric|min:0'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid ride completion data',
                    'errors' => $validator->errors()
                ], 422);
            }

            $rider = Rider::where('phone', auth()->user()->phone)->first();
            $ride = Ride::where('id', $request->ride_id)
                ->where('rider_id', $rider->id)
                ->where('status', 'in_transit')
                ->first();

            if (!$ride) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Active ride not found'
                ], 404);
            }

            // Update ride status and fare
            $ride->update([
                'status' => 'completed',
                'final_fare' => $request->final_fare ?? $ride->estimated_fare,
                'completed_at' => now()
            ]);

            // Update rider statistics
            $rider->increment('total_rides');

            Log::info('Ride completed', [
                'ride_id' => $ride->id,
                'rider_id' => $rider->id,
                'final_fare' => $ride->final_fare
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Ride completed successfully!',
                'data' => [
                    'ride_id' => $ride->id,
                    'final_fare' => $ride->final_fare,
                    'earnings' => $ride->final_fare, // In real app, calculate commission
                    'completed_at' => $ride->completed_at
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Ride completion failed', [
                'phone' => auth()->user()->phone,
                'ride_id' => $request->ride_id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to complete ride'
            ], 500);
        }
    }
}