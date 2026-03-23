<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class RoutePoint extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'route_id',
        'location_name',
        'location_address',
        'location_lat',
        'location_lon',
        'sequence_order',
        'estimated_arrival_min',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'location_lat' => 'decimal:8',
            'location_lon' => 'decimal:8',
            'sequence_order' => 'integer',
            'estimated_arrival_min' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * The model's boot method.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($routePoint) {
            // Automatically set PostGIS geometry field when creating
            $routePoint->setLocationGeometry();
        });

        static::updating(function ($routePoint) {
            // Automatically update PostGIS geometry field when updating coordinates
            if ($routePoint->isDirty(['location_lat', 'location_lon'])) {
                $routePoint->setLocationGeometry();
            }
        });
    }

    /**
     * Get the route this point belongs to
     */
    public function route()
    {
        return $this->belongsTo(Route::class);
    }

    /**
     * Set PostGIS geometry field from lat/lon
     */
    public function setLocationGeometry(): void
    {
        if ($this->location_lat && $this->location_lon) {
            $point = "POINT({$this->location_lon} {$this->location_lat})";

            DB::statement('
                UPDATE route_points
                SET location_geom = ST_GeomFromText(?, 4326)
                WHERE id = ?
            ', [$point, $this->id ?? 0]);
        }
    }

    /**
     * Calculate distance from this point to given coordinates
     */
    public function distanceFrom(float $lat, float $lon): float
    {
        $result = DB::selectOne('
            SELECT ST_Distance(
                location_geom::geography,
                ST_MakePoint(?, ?)::geography
            ) / 1000 as distance_km
            FROM route_points
            WHERE id = ?
        ', [$lon, $lat, $this->id]);

        return $result ? round($result->distance_km, 2) : 0;
    }

    /**
     * Find nearest route point to given coordinates
     */
    public static function findNearest(float $lat, float $lon, int $routeId = null): ?self
    {
        $query = self::selectRaw('
                route_points.*,
                ST_Distance(
                    location_geom::geography,
                    ST_MakePoint(?, ?)::geography
                ) / 1000 as distance_km
            ', [$lon, $lat])
            ->whereNotNull('location_geom')
            ->orderBy('distance_km');

        if ($routeId) {
            $query->where('route_id', $routeId);
        }

        return $query->first();
    }

    /**
     * Check if point is within radius of given coordinates
     */
    public function isWithinRadius(float $lat, float $lon, float $radiusKm = 0.5): bool
    {
        $result = DB::selectOne('
            SELECT ST_DWithin(
                location_geom::geography,
                ST_MakePoint(?, ?)::geography,
                ?
            ) as within_radius
            FROM route_points
            WHERE id = ?
        ', [$lon, $lat, $radiusKm * 1000, $this->id]);

        return $result ? $result->within_radius : false;
    }

    /**
     * Get coordinates as array
     */
    public function getCoordinatesAttribute(): array
    {
        return [
            'latitude' => $this->location_lat,
            'longitude' => $this->location_lon,
        ];
    }

    /**
     * Get display name
     */
    public function getDisplayNameAttribute(): string
    {
        return $this->location_name ?: $this->location_address ?: "Point {$this->sequence_order}";
    }

    /**
     * Scope for ordering by sequence
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('sequence_order');
    }

    /**
     * Get next route point in sequence
     */
    public function getNext(): ?self
    {
        return self::where('route_id', $this->route_id)
            ->where('sequence_order', '>', $this->sequence_order)
            ->orderBy('sequence_order')
            ->first();
    }

    /**
     * Get previous route point in sequence
     */
    public function getPrevious(): ?self
    {
        return self::where('route_id', $this->route_id)
            ->where('sequence_order', '<', $this->sequence_order)
            ->orderByDesc('sequence_order')
            ->first();
    }

    /**
     * Check if this is the first point in route
     */
    public function isFirst(): bool
    {
        return $this->sequence_order === 1;
    }

    /**
     * Check if this is the last point in route
     */
    public function isLast(): bool
    {
        $maxOrder = self::where('route_id', $this->route_id)->max('sequence_order');
        return $this->sequence_order === $maxOrder;
    }
}