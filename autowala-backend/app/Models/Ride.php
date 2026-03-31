<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Carbon\Carbon;

class Ride extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'rider_id',
        'pickup_location',
        'dropoff_location',
        'pickup_address',
        'dropoff_address',
        'pickup_time',
        'dropoff_time',
        'status',
        'passenger_count',
        'fare',
        'distance_km',
        'duration_minutes',
        'notes',
        'scheduled_at',
    ];

    /**
     * The attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'pickup_location' => 'array',
            'dropoff_location' => 'array',
            'pickup_time' => 'datetime',
            'dropoff_time' => 'datetime',
            'scheduled_at' => 'datetime',
            'passenger_count' => 'integer',
            'fare' => 'decimal:2',
            'distance_km' => 'decimal:2',
            'duration_minutes' => 'integer',
            'deleted_at' => 'datetime',
        ];
    }

    /**
     * The possible ride statuses
     */
    const STATUS_PENDING = 'pending';
    const STATUS_MATCHED = 'matched';
    const STATUS_IN_TRANSIT = 'in_transit';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * Get all possible statuses
     */
    public static function getStatuses(): array
    {
        return [
            self::STATUS_PENDING,
            self::STATUS_MATCHED,
            self::STATUS_IN_TRANSIT,
            self::STATUS_COMPLETED,
            self::STATUS_CANCELLED,
        ];
    }

    /**
     * Get the user who booked this ride
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the rider assigned to this ride
     */
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    /**
     * Get the detailed ride log for this ride
     */
    public function rideLog()
    {
        return $this->hasOne(RideLog::class);
    }

    /**
     * Get the rating for this ride
     */
    public function rating()
    {
        return $this->hasOne(UserRating::class);
    }

    /**
     * Get the vehicle used for this ride (through rider)
     */
    public function vehicle()
    {
        return $this->hasOneThrough(Vehicle::class, Rider::class, 'id', 'id', 'rider_id', 'vehicle_id');
    }

    /**
     * Assign a rider to this ride
     */
    public function assignRider(Rider $rider): bool
    {
        $updated = $this->update([
            'rider_id' => $rider->id,
            'status' => self::STATUS_MATCHED,
        ]);

        if ($updated) {
            // Create detailed ride log when matched
            $this->createRideLog();
        }

        return $updated;
    }

    /**
     * Start the ride
     */
    public function startRide(): bool
    {
        return $this->update([
            'status' => self::STATUS_IN_TRANSIT,
            'pickup_time' => now(),
        ]);
    }

    /**
     * Complete the ride
     */
    public function completeRide(array $data = []): bool
    {
        $updateData = array_merge([
            'status' => self::STATUS_COMPLETED,
            'dropoff_time' => now(),
        ], $data);

        // Calculate duration if pickup_time exists
        if ($this->pickup_time) {
            $updateData['duration_minutes'] = now()->diffInMinutes($this->pickup_time);
        }

        return $this->update($updateData);
    }

    /**
     * Cancel the ride
     */
    public function cancelRide(string $reason = null): bool
    {
        return $this->update([
            'status' => self::STATUS_CANCELLED,
            'notes' => $reason,
        ]);
    }

    /**
     * Create detailed ride log
     */
    protected function createRideLog(): RideLog
    {
        return RideLog::create([
            'user_id' => $this->user_id,
            'rider_id' => $this->rider_id,
            'vehicle_id' => $this->rider->vehicle_id ?? null,
            'pickup_location_name' => $this->pickup_address,
            'pickup_lat' => $this->pickup_location['latitude'] ?? null,
            'pickup_lon' => $this->pickup_location['longitude'] ?? null,
            'pickup_address' => $this->pickup_address,
            'dropoff_location_name' => $this->dropoff_address,
            'dropoff_lat' => $this->dropoff_location['latitude'] ?? null,
            'dropoff_lon' => $this->dropoff_location['longitude'] ?? null,
            'dropoff_address' => $this->dropoff_address,
            'status' => RideLog::STATUS_MATCHED,
            'no_of_passengers' => $this->passenger_count,
            'fare_amount' => $this->fare,
            'fare_currency' => 'INR',
            'firebase_session_id' => RideLog::generateFirebaseSessionId(),
        ]);
    }

    /**
     * Calculate estimated fare based on distance
     */
    public static function calculateFare(float $distanceKm, int $passengers = 1): float
    {
        $baseFare = 30.0; // Base fare in INR
        $perKmRate = 12.0; // Per km rate in INR
        $passengerMultiplier = max(1, $passengers);

        return ($baseFare + ($distanceKm * $perKmRate)) * $passengerMultiplier;
    }

    /**
     * Calculate distance between pickup and dropoff
     */
    public function calculateDistance(): ?float
    {
        if (!isset($this->pickup_location['latitude'], $this->pickup_location['longitude'],
                   $this->dropoff_location['latitude'], $this->dropoff_location['longitude'])) {
            return null;
        }

        return $this->haversineDistance(
            $this->pickup_location['latitude'],
            $this->pickup_location['longitude'],
            $this->dropoff_location['latitude'],
            $this->dropoff_location['longitude']
        );
    }

    /**
     * Calculate distance using Haversine formula
     */
    private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
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
     * Get pickup coordinates
     */
    public function getPickupCoordinatesAttribute(): array
    {
        return [
            'latitude' => $this->pickup_location['latitude'] ?? null,
            'longitude' => $this->pickup_location['longitude'] ?? null,
        ];
    }

    /**
     * Get dropoff coordinates
     */
    public function getDropoffCoordinatesAttribute(): array
    {
        return [
            'latitude' => $this->dropoff_location['latitude'] ?? null,
            'longitude' => $this->dropoff_location['longitude'] ?? null,
        ];
    }

    /**
     * Get formatted fare
     */
    public function getFormattedFareAttribute(): string
    {
        return '₹ ' . number_format($this->fare, 0);
    }

    /**
     * Check if ride is active
     */
    public function isActive(): bool
    {
        return in_array($this->status, [self::STATUS_PENDING, self::STATUS_MATCHED, self::STATUS_IN_TRANSIT]);
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
     * Scope for pending rides
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope for active rides
     */
    public function scopeActive($query)
    {
        return $query->whereIn('status', [self::STATUS_PENDING, self::STATUS_MATCHED, self::STATUS_IN_TRANSIT]);
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
     * Scope for rides by user
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope for rides by rider
     */
    public function scopeForRider($query, int $riderId)
    {
        return $query->where('rider_id', $riderId);
    }

    /**
     * Scope for recent rides
     */
    public function scopeRecent($query, int $days = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
}