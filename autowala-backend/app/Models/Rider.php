<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class Rider extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'full_name',
        'phone_number',
        'country_code',
        'profile_photo_url',
        'kyc_status',
        'vehicle_id',
        'average_rating',
        'total_rides',
        'is_online',
        'preferred_language',
        'fare_per_passenger',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'current_location', // Will be exposed via accessor
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'kyc_verified_at' => 'datetime',
            'last_online_at' => 'datetime',
            'location_updated_at' => 'datetime',
            'account_suspended_at' => 'datetime',
            'average_rating' => 'decimal:2',
            'fare_per_passenger' => 'decimal:2',
            'total_rides' => 'integer',
            'is_online' => 'boolean',
            'is_active' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    /**
     * Get the user associated with the rider
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the vehicle associated with the rider
     */
    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * Get the rider's routes
     */
    public function routes()
    {
        return $this->hasMany(Route::class);
    }

    /**
     * Get the rider's active routes
     */
    public function activeRoutes()
    {
        return $this->routes()->where('is_active', true);
    }

    /**
     * Get the rider's KYC documents
     */
    public function documents()
    {
        return $this->hasMany(Document::class);
    }

    /**
     * Get verified documents
     */
    public function verifiedDocuments()
    {
        return $this->documents()->where('is_verified', true);
    }

    /**
     * Get the rider's ride history
     */
    public function rideHistory()
    {
        return $this->hasMany(RideLog::class)->orderBy('created_at', 'desc');
    }

    /**
     * Get ratings received by the rider
     */
    public function ratingsReceived()
    {
        return $this->hasMany(UserRating::class, 'to_rider_id');
    }

    /**
     * Find nearby riders using PostGIS
     */
    public static function findNearby(float $lat, float $lon, float $radiusKm = 5): \Illuminate\Database\Eloquent\Collection
    {
        return self::selectRaw('
                riders.*,
                vehicles.registration_number,
                vehicles.color,
                vehicles.make,
                vehicles.model,
                ST_Distance(
                    riders.current_location::geography,
                    ST_MakePoint(?, ?)::geography
                ) / 1000 as distance_km,
                ST_X(riders.current_location) as longitude,
                ST_Y(riders.current_location) as latitude
            ', [$lon, $lat])
            ->join('vehicles', 'riders.vehicle_id', '=', 'vehicles.id')
            ->whereRaw('
                ST_DWithin(
                    riders.current_location::geography,
                    ST_MakePoint(?, ?)::geography,
                    ?
                )
            ', [$lon, $lat, $radiusKm * 1000])
            ->where('riders.is_online', true)
            ->where('riders.is_active', true)
            ->where('riders.kyc_status', 'verified')
            ->whereNotNull('riders.current_location')
            ->where('riders.location_updated_at', '>=', now()->subMinutes(5))
            ->orderBy('distance_km')
            ->limit(20)
            ->get();
    }

    /**
     * Find riders on specific route
     */
    public static function findOnRoute(float $startLat, float $startLon, float $endLat, float $endLon, float $bufferKm = 2): \Illuminate\Database\Eloquent\Collection
    {
        $routeLine = "LINESTRING({$startLon} {$startLat}, {$endLon} {$endLat})";

        return self::selectRaw('
                riders.*,
                vehicles.registration_number,
                vehicles.color,
                ST_Distance(
                    routes.route_geometry::geography,
                    ST_GeogFromText(?)
                ) / 1000 as route_distance_km,
                ST_X(riders.current_location) as longitude,
                ST_Y(riders.current_location) as latitude
            ', [$routeLine])
            ->join('vehicles', 'riders.vehicle_id', '=', 'vehicles.id')
            ->join('routes', 'riders.id', '=', 'routes.rider_id')
            ->whereRaw('
                ST_DWithin(
                    routes.route_geometry::geography,
                    ST_GeogFromText(?),
                    ?
                )
            ', [$routeLine, $bufferKm * 1000])
            ->where('riders.is_online', true)
            ->where('riders.is_active', true)
            ->where('riders.kyc_status', 'verified')
            ->where('routes.is_active', true)
            ->orderBy('route_distance_km')
            ->limit(15)
            ->get();
    }

    /**
     * Update rider location
     */
    public function updateLocation(float $lat, float $lon, ?int $heading = null): bool
    {
        $point = "POINT({$lon} {$lat})";

        return $this->update([
            'current_location' => DB::raw("ST_GeomFromText('{$point}', 4326)"),
            'location_updated_at' => now(),
        ]);
    }

    /**
     * Get current location as array
     */
    public function getCurrentLocationAttribute(): ?array
    {
        if (!$this->attributes['current_location']) {
            return null;
        }

        $result = DB::selectOne('
            SELECT ST_X(current_location) as longitude, ST_Y(current_location) as latitude
            FROM riders
            WHERE id = ?
        ', [$this->id]);

        if (!$result) {
            return null;
        }

        return [
            'latitude' => (float) $result->latitude,
            'longitude' => (float) $result->longitude,
        ];
    }

    /**
     * Check if location is recent (within 5 minutes)
     */
    public function hasRecentLocation(): bool
    {
        return $this->location_updated_at && $this->location_updated_at->isAfter(now()->subMinutes(5));
    }

    /**
     * Go online
     */
    public function goOnline(): bool
    {
        return $this->update([
            'is_online' => true,
            'last_online_at' => now(),
        ]);
    }

    /**
     * Go offline
     */
    public function goOffline(): bool
    {
        return $this->update([
            'is_online' => false,
        ]);
    }

    /**
     * Update rating after a ride
     */
    public function updateRating(): void
    {
        $avgRating = $this->ratingsReceived()->avg('rating');
        $totalRides = $this->rideHistory()->where('status', 'completed')->count();

        $this->update([
            'average_rating' => $avgRating ? round($avgRating, 2) : 5.0,
            'total_rides' => $totalRides,
        ]);
    }

    /**
     * Check if rider has completed KYC
     */
    public function hasCompletedKyc(): bool
    {
        return $this->kyc_status === 'verified';
    }

    /**
     * Check if rider has active routes
     */
    public function hasActiveRoutes(): bool
    {
        return $this->activeRoutes()->exists();
    }

    /**
     * Get current active ride
     */
    public function activeRide()
    {
        return $this->rideHistory()
            ->whereIn('status', ['matched', 'in_transit'])
            ->first();
    }

    /**
     * Scope for online riders
     */
    public function scopeOnline($query)
    {
        return $query->where('is_online', true);
    }

    /**
     * Scope for verified riders
     */
    public function scopeVerified($query)
    {
        return $query->where('kyc_status', 'verified');
    }

    /**
     * Scope for active riders
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for riders with recent location updates
     */
    public function scopeWithRecentLocation($query)
    {
        return $query->whereNotNull('current_location')
            ->where('location_updated_at', '>=', now()->subMinutes(5));
    }

    /**
     * Get formatted phone number
     */
    public function getFormattedPhoneAttribute(): string
    {
        return $this->country_code . $this->phone_number;
    }

    /**
     * Get display name for the rider
     */
    public function getDisplayNameAttribute(): string
    {
        return $this->full_name ?: 'Driver';
    }
}