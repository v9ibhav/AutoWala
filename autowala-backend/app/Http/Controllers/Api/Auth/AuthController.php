<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Services\Auth\OTPService;
use App\Services\Auth\JWTService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    protected $otpService;
    protected $jwtService;

    public function __construct(OTPService $otpService, JWTService $jwtService)
    {
        $this->otpService = $otpService;
        $this->jwtService = $jwtService;
    }

    /**
     * Send OTP to phone number
     */
    public function sendOTP(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => [
                'required',
                'string',
                'regex:/^[1-9]\d{9}$/', // Indian mobile number format
            ],
            'country_code' => 'nullable|string|max:5',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid phone number format',
                'errors' => $validator->errors(),
            ], 422);
        }

        $phoneNumber = $request->phone_number;
        $countryCode = $request->country_code ?? '+91';

        // Validate Indian phone number specifically
        if (!preg_match('/^[6-9]\d{9}$/', $phoneNumber)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Please enter a valid Indian mobile number',
            ], 422);
        }

        $result = $this->otpService->sendOTP($phoneNumber, $countryCode);

        $statusCode = $result['success'] ? 200 : 429;

        return response()->json([
            'status' => $result['success'] ? 'success' : 'error',
            'message' => $result['message'],
            'data' => array_diff_key($result, ['success' => true, 'message' => true]),
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ], $statusCode);
    }

    /**
     * Verify OTP and authenticate user
     */
    public function verifyOTP(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => [
                'required',
                'string',
                'regex:/^[6-9]\d{9}$/',
            ],
            'otp_code' => [
                'required',
                'string',
                'size:6',
                'regex:/^\d{6}$/',
            ],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $phoneNumber = $request->phone_number;
        $otpCode = $request->otp_code;

        // Verify OTP
        $otpResult = $this->otpService->verifyOTP($phoneNumber, $otpCode);

        if (!$otpResult['success']) {
            $statusCode = isset($otpResult['remaining_attempts']) && $otpResult['remaining_attempts'] > 0 ? 422 : 429;

            return response()->json([
                'status' => 'error',
                'message' => $otpResult['message'],
                'data' => array_diff_key($otpResult, ['success' => true, 'message' => true]),
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ], $statusCode);
        }

        // Generate JWT token
        $user = $otpResult['user'];
        $tokenResult = $this->jwtService->generateTokenForUser($user);

        if (!$tokenResult['success']) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to generate authentication token',
            ], 500);
        }

        Log::info('User authenticated successfully', [
            'user_id' => $user->id,
            'phone' => $phoneNumber,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Authentication successful',
            'data' => [
                'access_token' => $tokenResult['token'],
                'token_type' => $tokenResult['token_type'],
                'expires_in' => $tokenResult['expires_in'],
                'user' => $tokenResult['user'],
            ],
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ]);
    }

    /**
     * Resend OTP
     */
    public function resendOTP(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => [
                'required',
                'string',
                'regex:/^[6-9]\d{9}$/',
            ],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid phone number format',
                'errors' => $validator->errors(),
            ], 422);
        }

        $phoneNumber = $request->phone_number;
        $result = $this->otpService->resendOTP($phoneNumber);

        $statusCode = $result['success'] ? 200 : 429;

        return response()->json([
            'status' => $result['success'] ? 'success' : 'error',
            'message' => $result['message'],
            'data' => array_diff_key($result, ['success' => true, 'message' => true]),
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ], $statusCode);
    }

    /**
     * Refresh JWT token
     */
    public function refreshToken(): JsonResponse
    {
        $result = $this->jwtService->refreshToken();

        if (!$result['success']) {
            return response()->json([
                'status' => 'error',
                'message' => $result['message'],
            ], 401);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Token refreshed successfully',
            'data' => [
                'access_token' => $result['token'],
                'token_type' => $result['token_type'],
                'expires_in' => $result['expires_in'],
                'user' => $result['user'],
            ],
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ]);
    }

    /**
     * Logout user
     */
    public function logout(): JsonResponse
    {
        $result = $this->jwtService->invalidateToken();

        $statusCode = $result['success'] ? 200 : 500;

        return response()->json([
            'status' => $result['success'] ? 'success' : 'error',
            'message' => $result['message'],
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ], $statusCode);
    }

    /**
     * Get authenticated user profile
     */
    public function profile(): JsonResponse
    {
        $user = $this->jwtService->getAuthenticatedUser();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthenticated',
            ], 401);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'User profile retrieved successfully',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'phone_number' => $user->phone_number,
                    'country_code' => $user->country_code,
                    'full_name' => $user->full_name,
                    'email' => $user->email,
                    'profile_photo_url' => $user->profile_photo_url,
                    'is_verified' => $user->is_verified,
                    'preferred_language' => $user->preferred_language,
                    'notification_enabled' => $user->notification_enabled,
                    'created_at' => $user->created_at,
                    'is_rider' => $user->rider()->exists(),
                    'active_ride' => $user->activeRide(),
                ],
                'token_expires_at' => $this->jwtService->getTokenExpirationTime(),
            ],
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ]);
    }

    /**
     * Validate token
     */
    public function validateToken(): JsonResponse
    {
        $result = $this->jwtService->validateToken();

        $statusCode = $result['valid'] ? 200 : 401;

        return response()->json([
            'status' => $result['valid'] ? 'success' : 'error',
            'message' => $result['valid'] ? 'Token is valid' : 'Token is invalid',
            'data' => $result,
            'meta' => [
                'timestamp' => now()->toISOString(),
                'version' => '1.0',
            ],
        ], $statusCode);
    }
}