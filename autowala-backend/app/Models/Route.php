<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;

class Route extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'rider_id',
        'route_name',
        'description',
        'is_active',
        'total_distance_km',
        'estimated_duration_min',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'total_distance_km' => 'decimal:2',
            'estimated_duration_min' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    /**
     * Get the rider that owns this route
     */
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    /**
     * Get the route points (waypoints)
     */
    public function routePoints()
    {
        return $this->hasMany(RoutePoint::class)->orderBy('sequence_order');
    }

    /**
     * Get ride logs using this route
     */
    public function rideLogs()
    {
        return $this->hasMany(RideLog::class);
    }

    /**
     * Create route from coordinate array
     */
    public function setRouteFromCoordinates(array $coordinates): bool
    {
        if (count($coordinates) < 2) {
            return false;
        }

        // Create LINESTRING from coordinates
        $points = collect($coordinates)->map(function ($coord) {
            return "{$coord['lon']} {$coord['lat']}";
        })->join(', ');

        $linestring = "LINESTRING({$points})";

        return $this->update([
            'route_geometry' => DB::raw("ST_GeomFromText('{$linestring}', 4326)"),
        ]);
    }

    /**
     * Get route geometry as coordinates array
     */
    public function getRouteCoordinatesAttribute(): ?array
    {
        if (!$this->route_geometry) {
            return null;
        }

        $result = DB::selectOne('
            SELECT ST_AsText(route_geometry) as route_text
            FROM routes
            WHERE id = ?
        ', [$this->id]);

        if (!$result || !$result->route_text) {
            return null;
        }

        // Parse LINESTRING format: LINESTRING(lon lat, lon lat, ...)
        $linestring = str_replace(['LINESTRING(', ')'], '', $result->route_text);
        $points = explode(', ', $linestring);

        return collect($points)->map(function ($point) {
            [$lon, $lat] = explode(' ', $point);
            return [
                'latitude' => (float) $lat,
                'longitude' => (float) $lon,
            ];
        })->toArray();
    }

    /**
     * Check if route overlaps with given coordinates
     */
    public function overlapsWithRoute(float $startLat, float $startLon, float $endLat, float $endLon, float $bufferKm = 1): bool
    {
        $routeLine = "LINESTRING({$startLon} {$startLat}, {$endLon} {$endLat})";

        $result = DB::selectOne('
            SELECT ST_DWithin(
                route_geometry::geography,
                ST_GeogFromText(?),
                ?
            ) as overlaps
            FROM routes
            WHERE id = ?
        ', [$routeLine, $bufferKm * 1000, $this->id]);

        return $result ? $result->overlaps : false;
    }

    /**
     * Calculate route overlap percentage
     */
    public function calculateOverlapPercentage(float $startLat, float $startLon, float $endLat, float $endLon): float
    {
        $routeLine = "LINESTRING({$startLon} {$startLat}, {$endLon} {$endLat})";

        $result = DB::selectOne('
            SELECT
                ST_Length(route_geometry::geography) as route_length,
                ST_Length(
                    ST_Intersection(
                        ST_Buffer(route_geometry::geography, 1000),
                        ST_GeogFromText(?)
                    )
                ) as overlap_length
            FROM routes
            WHERE id = ?
        ', [$routeLine, $this->id]);

        if (!$result || $result->route_length == 0) {
            return 0;
        }

        return min(100, ($result->overlap_length / $result->route_length) * 100);
    }

    /**
     * Get start point of the route
     */
    public function getStartPointAttribute(): ?array
    {
        return $this->routePoints()->first()?->toArray();
    }

    /**
     * Get end point of the route
     */
    public function getEndPointAttribute(): ?array
    {
        return $this->routePoints()->orderByDesc('sequence_order')->first()?->toArray();
    }

    /**
     * Scope for active routes
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Get display name for the route
     */
    public function getDisplayNameAttribute(): string
    {
        if ($this->route_name) {
            return $this->route_name;
        }

        $startPoint = $this->startPoint;
        $endPoint = $this->endPoint;

        if ($startPoint && $endPoint) {
            return "{$startPoint['location_name']} to {$endPoint['location_name']}";
        }

        return 'Route #' . $this->id;
    }

    /**
     * Update route statistics
     */
    public function updateStatistics(): void
    {
        $result = DB::selectOne('
            SELECT
                ST_Length(route_geometry::geography) / 1000 as distance_km
            FROM routes
            WHERE id = ?
        ', [$this->id]);

        if ($result) {
            $this->update([
                'total_distance_km' => round($result->distance_km, 2),
                'estimated_duration_min' => round($result->distance_km * 2.5), // Assuming 25 km/h average speed
            ]);
        }
    }
}