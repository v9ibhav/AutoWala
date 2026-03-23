<?php

namespace App\Services\Location;

use App\Models\Rider;
use App\Models\Route;
use App\Models\RoutePoint;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class GeospatialService
{
    /**
     * Default search radius in kilometers
     */
    const DEFAULT_RADIUS_KM = 5;

    /**
     * Maximum search radius in kilometers
     */
    const MAX_RADIUS_KM = 25;

    /**
     * Route overlap buffer in kilometers
     */
    const ROUTE_OVERLAP_BUFFER_KM = 2;

    /**
     * Cache TTL for location queries in seconds
     */
    const CACHE_TTL_SECONDS = 30;

    /**
     * Find nearby riders using PostGIS
     */
    public function findNearbyRiders(
        float $latitude,
        float $longitude,
        float $radiusKm = self::DEFAULT_RADIUS_KM,
        int $limit = 20
    ): Collection {
        // Validate inputs
        $radiusKm = min($radiusKm, self::MAX_RADIUS_KM);
        $limit = min($limit, 50);

        // Create cache key
        $cacheKey = "nearby_riders:{$latitude}:{$longitude}:{$radiusKm}:{$limit}";

        return Cache::remember($cacheKey, self::CACHE_TTL_SECONDS, function () use ($latitude, $longitude, $radiusKm, $limit) {
            try {
                return DB::table('riders')
                    ->join('vehicles', 'riders.vehicle_id', '=', 'vehicles.id')
                    ->select([
                        'riders.id',
                        'riders.full_name',
                        'riders.phone_number',
                        'riders.average_rating',
                        'riders.total_rides',
                        'riders.fare_per_passenger',
                        'riders.location_updated_at',
                        'vehicles.registration_number',
                        'vehicles.color',
                        'vehicles.make',
                        'vehicles.model',
                        'vehicles.max_passengers',
                        DB::raw('
                            ST_Distance(
                                riders.current_location::geography,
                                ST_MakePoint(?, ?)::geography
                            ) / 1000 as distance_km
                        '),
                        DB::raw('ST_X(riders.current_location) as longitude'),
                        DB::raw('ST_Y(riders.current_location) as latitude'),
                        DB::raw('
                            ROUND(
                                ST_Distance(
                                    riders.current_location::geography,
                                    ST_MakePoint(?, ?)::geography
                                ) / (25 * 1000 / 60) -- Assuming 25 km/h average speed
                            ) as estimated_eta_minutes
                        '),
                    ])
                    ->setBindings([$longitude, $latitude, $longitude, $latitude])
                    ->whereRaw('
                        ST_DWithin(
                            riders.current_location::geography,
                            ST_MakePoint(?, ?)::geography,
                            ?
                        )
                    ', [$longitude, $latitude, $radiusKm * 1000])
                    ->where('riders.is_online', true)
                    ->where('riders.is_active', true)
                    ->where('riders.kyc_status', 'verified')
                    ->where('vehicles.is_verified', true)
                    ->whereNotNull('riders.current_location')
                    ->where('riders.location_updated_at', '>=', now()->subMinutes(5))
                    ->orderBy('distance_km')
                    ->limit($limit)
                    ->get()
                    ->map(function ($rider) {
                        return (object) [
                            'id' => $rider->id,
                            'full_name' => $rider->full_name,
                            'phone_number' => $rider->phone_number,
                            'average_rating' => (float) $rider->average_rating,
                            'total_rides' => (int) $rider->total_rides,
                            'fare_per_passenger' => (float) $rider->fare_per_passenger,
                            'distance_km' => round((float) $rider->distance_km, 2),
                            'estimated_eta_minutes' => (int) $rider->estimated_eta_minutes,
                            'current_location' => [
                                'latitude' => (float) $rider->latitude,
                                'longitude' => (float) $rider->longitude,
                            ],
                            'vehicle' => [
                                'registration_number' => $rider->registration_number,
                                'color' => $rider->color,
                                'make' => $rider->make,
                                'model' => $rider->model,
                                'max_passengers' => (int) $rider->max_passengers,
                                'display_name' => trim($rider->make . ' ' . $rider->model . ' ' . $rider->color),
                            ],
                            'location_updated_at' => $rider->location_updated_at,
                        ];
                    });

            } catch (\Exception $e) {
                Log::error('Failed to find nearby riders', [
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                    'radius_km' => $radiusKm,
                    'error' => $e->getMessage()
                ]);

                return collect([]);
            }
        });
    }

    /**
     * Find riders on a specific route
     */
    public function findRidersOnRoute(
        float $startLatitude,
        float $startLongitude,
        float $endLatitude,
        float $endLongitude,
        float $bufferKm = self::ROUTE_OVERLAP_BUFFER_KM,
        int $limit = 15
    ): Collection {
        try {
            $routeLine = "LINESTRING({$startLongitude} {$startLatitude}, {$endLongitude} {$endLatitude})";

            return DB::table('riders')
                ->join('vehicles', 'riders.vehicle_id', '=', 'vehicles.id')
                ->join('routes', 'riders.id', '=', 'routes.rider_id')
                ->select([
                    'riders.id',
                    'riders.full_name',
                    'riders.phone_number',
                    'riders.average_rating',
                    'riders.fare_per_passenger',
                    'vehicles.registration_number',
                    'vehicles.color',
                    'routes.route_name',
                    'routes.total_distance_km',
                    DB::raw('
                        ST_Distance(
                            routes.route_geometry::geography,
                            ST_GeogFromText(?)
                        ) / 1000 as route_distance_km
                    '),
                    DB::raw('ST_X(riders.current_location) as longitude'),
                    DB::raw('ST_Y(riders.current_location) as latitude'),
                    DB::raw('
                        ROUND(
                            (ST_Distance(
                                riders.current_location::geography,
                                ST_ClosestPoint(
                                    routes.route_geometry::geography,
                                    riders.current_location::geography
                                )
                            ) + ST_Distance(
                                ST_ClosestPoint(
                                    routes.route_geometry::geography,
                                    riders.current_location::geography
                                ),
                                ST_GeogFromText(?)
                            )) / (20 * 1000 / 60) -- 20 km/h with traffic
                        ) as estimated_eta_minutes
                    '),
                ])
                ->setBindings([$routeLine, $routeLine])
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
                ->where('vehicles.is_verified', true)
                ->where('routes.is_active', true)
                ->whereNotNull('riders.current_location')
                ->where('riders.location_updated_at', '>=', now()->subMinutes(5))
                ->orderBy('route_distance_km')
                ->limit($limit)
                ->get()
                ->map(function ($rider) {
                    return (object) [
                        'id' => $rider->id,
                        'full_name' => $rider->full_name,
                        'phone_number' => $rider->phone_number,
                        'average_rating' => (float) $rider->average_rating,
                        'fare_per_passenger' => (float) $rider->fare_per_passenger,
                        'route_distance_km' => round((float) $rider->route_distance_km, 2),
                        'estimated_eta_minutes' => (int) $rider->estimated_eta_minutes,
                        'current_location' => [
                            'latitude' => (float) $rider->latitude,
                            'longitude' => (float) $rider->longitude,
                        ],
                        'vehicle' => [
                            'registration_number' => $rider->registration_number,
                            'color' => $rider->color,
                        ],
                        'route' => [
                            'name' => $rider->route_name,
                            'total_distance_km' => (float) $rider->total_distance_km,
                        ],
                    ];
                });

        } catch (\Exception $e) {
            Log::error('Failed to find riders on route', [
                'start' => [$startLatitude, $startLongitude],
                'end' => [$endLatitude, $endLongitude],
                'buffer_km' => $bufferKm,
                'error' => $e->getMessage()
            ]);

            return collect([]);
        }
    }

    /**
     * Calculate distance between two points
     */
    public function calculateDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2,
        string $unit = 'km'
    ): float {
        try {
            $result = DB::selectOne('
                SELECT ST_Distance(
                    ST_MakePoint(?, ?)::geography,
                    ST_MakePoint(?, ?)::geography
                ) as distance_meters
            ', [$lon1, $lat1, $lon2, $lat2]);

            if (!$result) {
                return 0;
            }

            $distanceMeters = (float) $result->distance_meters;

            return match ($unit) {
                'km' => round($distanceMeters / 1000, 2),
                'm', 'meters' => round($distanceMeters, 2),
                'miles' => round($distanceMeters * 0.000621371, 2),
                default => round($distanceMeters / 1000, 2),
            };

        } catch (\Exception $e) {
            Log::error('Failed to calculate distance', [
                'point1' => [$lat1, $lon1],
                'point2' => [$lat2, $lon2],
                'error' => $e->getMessage()
            ]);

            return 0;
        }
    }

    /**
     * Find nearest route point to given coordinates
     */
    public function findNearestRoutePoint(
        float $latitude,
        float $longitude,
        ?int $routeId = null,
        float $maxDistanceKm = 1
    ): ?object {
        try {
            $query = DB::table('route_points')
                ->select([
                    'route_points.*',
                    'routes.route_name',
                    'routes.rider_id',
                    DB::raw('
                        ST_Distance(
                            location_geom::geography,
                            ST_MakePoint(?, ?)::geography
                        ) / 1000 as distance_km
                    ')
                ])
                ->join('routes', 'route_points.route_id', '=', 'routes.id')
                ->setBindings([$longitude, $latitude])
                ->whereRaw('
                    ST_DWithin(
                        location_geom::geography,
                        ST_MakePoint(?, ?)::geography,
                        ?
                    )
                ', [$longitude, $latitude, $maxDistanceKm * 1000])
                ->whereNotNull('location_geom')
                ->where('routes.is_active', true)
                ->orderBy('distance_km');

            if ($routeId) {
                $query->where('route_points.route_id', $routeId);
            }

            $result = $query->first();

            if (!$result) {
                return null;
            }

            return (object) [
                'id' => $result->id,
                'route_id' => $result->route_id,
                'location_name' => $result->location_name,
                'location_address' => $result->location_address,
                'coordinates' => [
                    'latitude' => (float) $result->location_lat,
                    'longitude' => (float) $result->location_lon,
                ],
                'sequence_order' => (int) $result->sequence_order,
                'estimated_arrival_min' => $result->estimated_arrival_min,
                'distance_km' => round((float) $result->distance_km, 2),
                'route_name' => $result->route_name,
                'rider_id' => $result->rider_id,
            ];

        } catch (\Exception $e) {
            Log::error('Failed to find nearest route point', [
                'latitude' => $latitude,
                'longitude' => $longitude,
                'route_id' => $routeId,
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Check if a location is within Indian boundaries
     */
    public function isLocationInIndia(float $latitude, float $longitude): bool
    {
        // Approximate bounding box for India
        return $latitude >= 6.5 && $latitude <= 37.5 &&
               $longitude >= 68.0 && $longitude <= 97.5;
    }

    /**
     * Validate coordinates
     */
    public function areValidCoordinates(float $latitude, float $longitude): bool
    {
        return $latitude >= -90 && $latitude <= 90 &&
               $longitude >= -180 && $longitude <= 180;
    }

    /**
     * Calculate route overlap percentage
     */
    public function calculateRouteOverlap(
        int $routeId,
        float $startLatitude,
        float $startLongitude,
        float $endLatitude,
        float $endLongitude,
        float $bufferKm = 1
    ): float {
        try {
            $userRouteLine = "LINESTRING({$startLongitude} {$startLatitude}, {$endLongitude} {$endLatitude})";

            $result = DB::selectOne('
                SELECT
                    ST_Length(route_geometry::geography) as route_length,
                    ST_Length(
                        ST_Intersection(
                            ST_Buffer(route_geometry::geography, ?),
                            ST_GeogFromText(?)
                        )
                    ) as overlap_length
                FROM routes
                WHERE id = ? AND route_geometry IS NOT NULL
            ', [$bufferKm * 1000, $userRouteLine, $routeId]);

            if (!$result || $result->route_length == 0) {
                return 0;
            }

            $overlapPercentage = ($result->overlap_length / $result->route_length) * 100;
            return min(100, max(0, round($overlapPercentage, 1)));

        } catch (\Exception $e) {
            Log::error('Failed to calculate route overlap', [
                'route_id' => $routeId,
                'start' => [$startLatitude, $startLongitude],
                'end' => [$endLatitude, $endLongitude],
                'error' => $e->getMessage()
            ]);

            return 0;
        }
    }

    /**
     * Get coordinates within a polygon (for geofencing)
     */
    public function getCoordinatesWithinPolygon(array $polygonCoordinates, string $table = 'riders'): Collection
    {
        try {
            // Convert polygon coordinates to PostGIS format
            $polygonPoints = collect($polygonCoordinates)->map(function ($coord) {
                return $coord['longitude'] . ' ' . $coord['latitude'];
            })->join(', ');

            // Close the polygon by adding the first point at the end
            $firstPoint = $polygonCoordinates[0];
            $polygonPoints .= ', ' . $firstPoint['longitude'] . ' ' . $firstPoint['latitude'];

            $polygon = "POLYGON(($polygonPoints))";

            return DB::table($table)
                ->whereRaw('
                    ST_Contains(
                        ST_GeomFromText(?, 4326),
                        current_location
                    )
                ', [$polygon])
                ->whereNotNull('current_location')
                ->get();

        } catch (\Exception $e) {
            Log::error('Failed to get coordinates within polygon', [
                'polygon_coordinates_count' => count($polygonCoordinates),
                'table' => $table,
                'error' => $e->getMessage()
            ]);

            return collect([]);
        }
    }

    /**
     * Clear location cache
     */
    public function clearLocationCache(float $latitude, float $longitude): void
    {
        $patterns = [
            "nearby_riders:{$latitude}:{$longitude}:*",
            "route_riders:{$latitude}:{$longitude}:*",
        ];

        foreach ($patterns as $pattern) {
            Cache::forget($pattern);
        }
    }

    /**
     * Batch update rider locations
     */
    public function batchUpdateRiderLocations(array $locationUpdates): array
    {
        $successCount = 0;
        $failedUpdates = [];

        DB::transaction(function () use ($locationUpdates, &$successCount, &$failedUpdates) {
            foreach ($locationUpdates as $update) {
                try {
                    $riderId = $update['rider_id'];
                    $latitude = $update['latitude'];
                    $longitude = $update['longitude'];

                    // Validate coordinates
                    if (!$this->areValidCoordinates($latitude, $longitude) ||
                        !$this->isLocationInIndia($latitude, $longitude)) {
                        throw new \Exception('Invalid coordinates for Indian location');
                    }

                    $point = "POINT({$longitude} {$latitude})";

                    DB::table('riders')
                        ->where('id', $riderId)
                        ->where('is_online', true)
                        ->update([
                            'current_location' => DB::raw("ST_GeomFromText('{$point}', 4326)"),
                            'location_updated_at' => now(),
                        ]);

                    $successCount++;

                    // Clear cache for this location
                    $this->clearLocationCache($latitude, $longitude);

                } catch (\Exception $e) {
                    $failedUpdates[] = [
                        'rider_id' => $update['rider_id'] ?? null,
                        'error' => $e->getMessage(),
                    ];
                }
            }
        });

        return [
            'total_updates' => count($locationUpdates),
            'successful_updates' => $successCount,
            'failed_updates' => count($failedUpdates),
            'failures' => $failedUpdates,
        ];
    }
}