<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class RideLog extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'rider_id',
        'vehicle_id',
        'route_id',
        'pickup_location_name',
        'pickup_lat',
        'pickup_lon',
        'pickup_address',
        'dropoff_location_name',
        'dropoff_lat',
        'dropoff_lon',
        'dropoff_address',
        'status',
        'no_of_passengers',
        'fare_amount',
        'fare_currency',
        'pickup_route_index',
        'estimated_pickup_time',
        'estimated_dropoff_time',
        'actual_pickup_time',
        'actual_dropoff_time',
        'actual_distance_km',
        'actual_duration_min',
        'firebase_session_id',
        'cancelled_by',
        'cancelled_at',
        'cancellation_reason',
        'completed_at',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'pickup_lat' => 'decimal:8',
            'pickup_lon' => 'decimal:8',
            'dropoff_lat' => 'decimal:8',
            'dropoff_lon' => 'decimal:8',
            'pickup_time' => 'datetime',
            'dropoff_time' => 'datetime',
            'estimated_pickup_time' => 'datetime',
            'estimated_dropoff_time' => 'datetime',
            'actual_pickup_time' => 'datetime',
            'actual_dropoff_time' => 'datetime',
            'cancelled_at' => 'datetime',
            'completed_at' => 'datetime',
            'no_of_passengers' => 'integer',
            'fare_amount' => 'decimal:2',
            'actual_distance_km' => 'decimal:2',
            'actual_duration_min' => 'integer',
            'pickup_route_index' => 'integer',
            'is_user_picked_up' => 'boolean',
            'is_ride_completed' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * The possible ride statuses
     */
    const STATUS_MATCHED = 'matched';
    const STATUS_IN_TRANSIT = 'in_transit';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * Get the user that booked this ride
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the rider for this ride
     */
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    /**
     * Get the vehicle used for this ride
     */
    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * Get the route used for this ride
     */
    public function route()
    {
        return $this->belongsTo(Route::class);
    }

    /**
     * Get the rating for this ride
     */
    public function rating()
    {
        return $this->hasOne(UserRating::class);
    }

    /**
     * Get tracking history for this ride
     */
    public function trackingHistory()
    {
        return $this->hasMany(RideTrackingHistory::class)->orderBy('recorded_at');
    }

    /**
     * Generate unique Firebase session ID
     */
    public static function generateFirebaseSessionId(): string
    {
        do {
            $sessionId = 'session_' . bin2hex(random_bytes(8)) . '_' . time();
        } while (self::where('firebase_session_id', $sessionId)->exists());

        return $sessionId;
    }

    /**
     * Start the ride (user pickup confirmation)
     */
    public function startRide(): bool
    {
        return $this->update([
            'status' => self::STATUS_IN_TRANSIT,
            'is_user_picked_up' => true,
            'actual_pickup_time' => now(),
        ]);
    }

    /**
     * Complete the ride
     */
    public function completeRide(?float $actualDistanceKm = null): bool
    {
        $updateData = [
            'status' => self::STATUS_COMPLETED,
            'is_ride_completed' => true,
            'actual_dropoff_time' => now(),
            'completed_at' => now(),
        ];

        // Calculate actual duration
        if ($this->actual_pickup_time) {
            $duration = now()->diffInMinutes($this->actual_pickup_time);
            $updateData['actual_duration_min'] = $duration;
        }

        // Set actual distance if provided
        if ($actualDistanceKm) {
            $updateData['actual_distance_km'] = $actualDistanceKm;
        }

        return $this->update($updateData);
    }

    /**
     * Cancel the ride
     */
    public function cancelRide(string $cancelledBy, ?string $reason = null): bool
    {
        return $this->update([
            'status' => self::STATUS_CANCELLED,
            'cancelled_by' => $cancelledBy,
            'cancelled_at' => now(),
            'cancellation_reason' => $reason,
        ]);
    }

    /**
     * Calculate estimated pickup time based on rider location and pickup point
     */
    public function calculateEstimatedPickupTime(?float $riderLat = null, ?float $riderLon = null): ?Carbon
    {
        if (!$riderLat || !$riderLon || !$this->pickup_lat || !$this->pickup_lon) {
            return null;
        }

        // Simple distance calculation and time estimation
        $distance = $this->calculateDistance($riderLat, $riderLon, $this->pickup_lat, $this->pickup_lon);
        $estimatedMinutes = ($distance / 25) * 60; // Assuming 25 km/h average speed

        return now()->addMinutes($estimatedMinutes);
    }

    /**
     * Calculate estimated dropoff time
     */
    public function calculateEstimatedDropoffTime(): ?Carbon
    {
        if (!$this->pickup_lat || !$this->pickup_lon || !$this->dropoff_lat || !$this->dropoff_lon) {
            return null;
        }

        $distance = $this->calculateDistance(
            $this->pickup_lat,
            $this->pickup_lon,
            $this->dropoff_lat,
            $this->dropoff_lon
        );

        $estimatedMinutes = ($distance / 20) * 60; // Assuming 20 km/h average speed with traffic

        $startTime = $this->estimated_pickup_time ?: now();
        return $startTime->copy()->addMinutes($estimatedMinutes);
    }

    /**
     * Calculate distance between two coordinates
     */
    private function calculateDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371; // Earth's radius in kilometers

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Get pickup coordinates as array
     */
    public function getPickupCoordinatesAttribute(): array
    {
        return [
            'latitude' => $this->pickup_lat,
            'longitude' => $this->pickup_lon,
        ];
    }

    /**
     * Get dropoff coordinates as array
     */
    public function getDropoffCoordinatesAttribute(): array
    {
        return [
            'latitude' => $this->dropoff_lat,
            'longitude' => $this->dropoff_lon,
        ];
    }

    /**
     * Check if ride is active (ongoing)
     */
    public function isActive(): bool
    {
        return in_array($this->status, [self::STATUS_MATCHED, self::STATUS_IN_TRANSIT]);
    }

    /**
     * Check if ride is completed
     */
    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    /**
     * Check if ride is cancelled
     */
    public function isCancelled(): bool
    {
        return $this->status === self::STATUS_CANCELLED;
    }

    /**
     * Get time until pickup estimate
     */
    public function getTimeUntilPickupAttribute(): ?int
    {
        if (!$this->estimated_pickup_time) {
            return null;
        }

        $minutes = now()->diffInMinutes($this->estimated_pickup_time, false);
        return $minutes > 0 ? $minutes : 0;
    }

    /**
     * Get formatted fare
     */
    public function getFormattedFareAttribute(): string
    {
        return ($this->fare_currency ?: 'INR') . ' ' . number_format($this->fare_amount, 0);
    }

    /**
     * Scope for active rides
     */
    public function scopeActive($query)
    {
        return $query->whereIn('status', [self::STATUS_MATCHED, self::STATUS_IN_TRANSIT]);
    }

    /**
     * Scope for completed rides
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', self::STATUS_COMPLETED);
    }

    /**
     * Scope for cancelled rides
     */
    public function scopeCancelled($query)
    {
        return $query->where('status', self::STATUS_CANCELLED);
    }

    /**
     * Scope for rides within date range
     */
    public function scopeWithinDateRange($query, Carbon $startDate, Carbon $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }
}