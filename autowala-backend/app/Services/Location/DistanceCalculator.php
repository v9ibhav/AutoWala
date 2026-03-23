<?php

namespace App\Services\Location;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DistanceCalculator
{
    /**
     * Average speeds for different modes in km/h
     */
    const AVERAGE_SPEEDS = [
        'auto_rickshaw' => 25,      // Normal traffic
        'auto_rickshaw_heavy' => 15, // Heavy traffic
        'walking' => 5,
        'bicycle' => 15,
    ];

    /**
     * Traffic factors for different times
     */
    const TRAFFIC_FACTORS = [
        'peak_morning' => 0.6,    // 8-10 AM
        'peak_evening' => 0.6,    // 5-8 PM
        'normal' => 0.8,          // Regular traffic
        'light' => 1.0,           // Minimal traffic
    ];

    /**
     * Calculate haversine distance between two points
     */
    public function haversineDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2,
        string $unit = 'km'
    ): float {
        $earthRadius = match ($unit) {
            'km' => 6371,
            'miles' => 3959,
            'm', 'meters' => 6371000,
            default => 6371,
        };

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        $distance = $earthRadius * $c;

        return round($distance, 2);
    }

    /**
     * Calculate estimated travel time
     */
    public function calculateTravelTime(
        float $distanceKm,
        string $mode = 'auto_rickshaw',
        ?string $trafficCondition = null
    ): array {
        try {
            // Get base speed
            $baseSpeed = self::AVERAGE_SPEEDS[$mode] ?? self::AVERAGE_SPEEDS['auto_rickshaw'];

            // Apply traffic factor
            $trafficCondition = $trafficCondition ?? $this->getCurrentTrafficCondition();
            $trafficFactor = self::TRAFFIC_FACTORS[$trafficCondition] ?? self::TRAFFIC_FACTORS['normal'];
            $effectiveSpeed = $baseSpeed * $trafficFactor;

            // Calculate time in minutes
            $timeMinutes = ($distanceKm / $effectiveSpeed) * 60;

            // Add buffer time (10% minimum, more for longer distances)
            $bufferFactor = max(0.1, min(0.3, $distanceKm * 0.02));
            $totalTimeMinutes = $timeMinutes * (1 + $bufferFactor);

            return [
                'distance_km' => round($distanceKm, 2),
                'base_time_minutes' => round($timeMinutes, 0),
                'estimated_time_minutes' => round($totalTimeMinutes, 0),
                'traffic_condition' => $trafficCondition,
                'traffic_factor' => $trafficFactor,
                'effective_speed_kmh' => round($effectiveSpeed, 1),
                'arrival_time' => now()->addMinutes($totalTimeMinutes)->format('H:i'),
            ];

        } catch (\Exception $e) {
            Log::error('Failed to calculate travel time', [
                'distance_km' => $distanceKm,
                'mode' => $mode,
                'traffic_condition' => $trafficCondition,
                'error' => $e->getMessage()
            ]);

            // Fallback calculation
            $fallbackTime = max(5, ($distanceKm / 20) * 60); // 20 km/h fallback speed

            return [
                'distance_km' => round($distanceKm, 2),
                'estimated_time_minutes' => round($fallbackTime, 0),
                'traffic_condition' => 'unknown',
                'fallback' => true,
            ];
        }
    }

    /**
     * Get directions using Google Maps API
     */
    public function getDirections(
        float $originLat,
        float $originLon,
        float $destLat,
        float $destLon,
        string $mode = 'driving'
    ): ?array {
        try {
            $cacheKey = "directions:{$originLat}:{$originLon}:{$destLat}:{$destLon}:{$mode}";

            return Cache::remember($cacheKey, 1800, function () use ($originLat, $originLon, $destLat, $destLon, $mode) {
                $apiKey = config('googlemaps.api_key');

                if (!$apiKey) {
                    Log::warning('Google Maps API key not configured');
                    return null;
                }

                $response = Http::get(config('googlemaps.endpoints.directions'), [
                    'origin' => "{$originLat},{$originLon}",
                    'destination' => "{$destLat},{$destLon}",
                    'mode' => $mode,
                    'region' => 'IN',
                    'language' => 'en',
                    'key' => $apiKey,
                    'traffic_model' => 'best_guess',
                    'departure_time' => 'now',
                ]);

                if (!$response->successful()) {
                    Log::error('Google Directions API request failed', [
                        'status' => $response->status(),
                        'response' => $response->body()
                    ]);
                    return null;
                }

                $data = $response->json();

                if ($data['status'] !== 'OK' || empty($data['routes'])) {
                    Log::warning('No routes found in Google Directions response', ['data' => $data]);
                    return null;
                }

                $route = $data['routes'][0];
                $leg = $route['legs'][0];

                return [
                    'distance' => [
                        'text' => $leg['distance']['text'],
                        'value_meters' => $leg['distance']['value'],
                        'value_km' => round($leg['distance']['value'] / 1000, 2),
                    ],
                    'duration' => [
                        'text' => $leg['duration']['text'],
                        'value_seconds' => $leg['duration']['value'],
                        'value_minutes' => round($leg['duration']['value'] / 60, 0),
                    ],
                    'duration_in_traffic' => isset($leg['duration_in_traffic']) ? [
                        'text' => $leg['duration_in_traffic']['text'],
                        'value_seconds' => $leg['duration_in_traffic']['value'],
                        'value_minutes' => round($leg['duration_in_traffic']['value'] / 60, 0),
                    ] : null,
                    'start_address' => $leg['start_address'],
                    'end_address' => $leg['end_address'],
                    'polyline' => $route['overview_polyline']['points'],
                    'bounds' => $route['bounds'],
                    'steps' => collect($leg['steps'])->map(function ($step) {
                        return [
                            'distance' => $step['distance'],
                            'duration' => $step['duration'],
                            'instructions' => strip_tags($step['html_instructions']),
                            'travel_mode' => $step['travel_mode'],
                            'start_location' => $step['start_location'],
                            'end_location' => $step['end_location'],
                        ];
                    })->toArray(),
                ];
            });

        } catch (\Exception $e) {
            Log::error('Failed to get directions from Google Maps', [
                'origin' => [$originLat, $originLon],
                'destination' => [$destLat, $destLon],
                'mode' => $mode,
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Calculate multiple waypoint distances
     */
    public function calculateMultipleDistances(array $waypoints): array
    {
        $results = [];
        $totalDistance = 0;
        $totalTime = 0;

        for ($i = 0; $i < count($waypoints) - 1; $i++) {
            $from = $waypoints[$i];
            $to = $waypoints[$i + 1];

            $distance = $this->haversineDistance(
                $from['latitude'],
                $from['longitude'],
                $to['latitude'],
                $to['longitude']
            );

            $travelTime = $this->calculateTravelTime($distance);

            $results[] = [
                'segment' => $i + 1,
                'from' => $from,
                'to' => $to,
                'distance_km' => $distance,
                'travel_time' => $travelTime,
            ];

            $totalDistance += $distance;
            $totalTime += $travelTime['estimated_time_minutes'];
        }

        return [
            'segments' => $results,
            'total_distance_km' => round($totalDistance, 2),
            'total_time_minutes' => round($totalTime, 0),
            'waypoint_count' => count($waypoints),
        ];
    }

    /**
     * Find optimal pickup point along route
     */
    public function findOptimalPickupPoint(
        float $userLat,
        float $userLon,
        array $routePoints
    ): ?array {
        $minDistance = PHP_FLOAT_MAX;
        $optimalPoint = null;

        foreach ($routePoints as $index => $point) {
            $distance = $this->haversineDistance(
                $userLat,
                $userLon,
                $point['latitude'],
                $point['longitude']
            );

            if ($distance < $minDistance) {
                $minDistance = $distance;
                $optimalPoint = [
                    'index' => $index,
                    'point' => $point,
                    'distance_km' => $distance,
                    'walk_time_minutes' => round(($distance * 1000) / (5 * 1000 / 60), 0), // 5 km/h walking speed
                ];
            }
        }

        // Only return if within reasonable walking distance (1km)
        return $optimalPoint && $optimalPoint['distance_km'] <= 1.0 ? $optimalPoint : null;
    }

    /**
     * Determine current traffic condition based on time
     */
    public function getCurrentTrafficCondition(): string
    {
        $hour = now()->hour;
        $dayOfWeek = now()->dayOfWeek;

        // Weekend traffic is generally lighter
        if ($dayOfWeek == 0 || $dayOfWeek == 6) { // Sunday or Saturday
            return in_array($hour, [10, 11, 12, 19, 20]) ? 'normal' : 'light';
        }

        // Weekday traffic patterns
        return match (true) {
            $hour >= 8 && $hour <= 10 => 'peak_morning',
            $hour >= 17 && $hour <= 20 => 'peak_evening',
            $hour >= 11 && $hour <= 16 => 'normal',
            default => 'light',
        };
    }

    /**
     * Calculate fare estimate based on distance and time
     */
    public function calculateFareEstimate(
        float $distanceKm,
        int $timeMinutes,
        float $baseRate = 30.0
    ): array {
        try {
            // Base fare calculation
            $baseFare = $baseRate;

            // Distance component (₹3 per km after first 2km)
            $distanceFare = max(0, ($distanceKm - 2) * 3);

            // Time component (₹1 per minute after first 5 minutes)
            $timeFare = max(0, ($timeMinutes - 5) * 1);

            // Total fare
            $totalFare = $baseFare + $distanceFare + $timeFare;

            // Apply surge pricing during peak hours
            $surgeFactor = $this->getSurgeFactor();
            $finalFare = $totalFare * $surgeFactor;

            return [
                'distance_km' => round($distanceKm, 2),
                'time_minutes' => $timeMinutes,
                'base_fare' => $baseFare,
                'distance_fare' => round($distanceFare, 2),
                'time_fare' => round($timeFare, 2),
                'surge_factor' => $surgeFactor,
                'total_fare' => round($finalFare, 0),
                'fare_breakdown' => [
                    'base' => "₹{$baseFare} (base)",
                    'distance' => "₹" . round($distanceFare, 2) . " (distance)",
                    'time' => "₹" . round($timeFare, 2) . " (time)",
                    'surge' => $surgeFactor > 1 ? "x{$surgeFactor} surge" : null,
                ],
            ];

        } catch (\Exception $e) {
            Log::error('Failed to calculate fare estimate', [
                'distance_km' => $distanceKm,
                'time_minutes' => $timeMinutes,
                'base_rate' => $baseRate,
                'error' => $e->getMessage()
            ]);

            return [
                'total_fare' => $baseRate,
                'error' => 'Could not calculate detailed fare',
            ];
        }
    }

    /**
     * Get surge factor based on current conditions
     */
    private function getSurgeFactor(): float
    {
        $trafficCondition = $this->getCurrentTrafficCondition();
        $hour = now()->hour;
        $dayOfWeek = now()->dayOfWeek;

        // No surge on AutoWala since it's discovery only
        // But calculate for display purposes
        return match ($trafficCondition) {
            'peak_morning', 'peak_evening' => 1.2,
            'normal' => 1.0,
            'light' => 1.0,
            default => 1.0,
        };
    }

    /**
     * Validate coordinates are within reasonable bounds
     */
    public function areCoordinatesReasonable(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2
    ): bool {
        // Check if coordinates are valid
        if ($lat1 < -90 || $lat1 > 90 || $lon1 < -180 || $lon1 > 180 ||
            $lat2 < -90 || $lat2 > 90 || $lon2 < -180 || $lon2 > 180) {
            return false;
        }

        // Check if distance is reasonable (less than 100km for city rides)
        $distance = $this->haversineDistance($lat1, $lon1, $lat2, $lon2);
        return $distance <= 100;
    }

    /**
     * Convert coordinates to Indian postal code area (approximate)
     */
    public function getApproximateArea(float $latitude, float $longitude): ?string
    {
        // This is a simplified implementation
        // In production, you'd use a proper geocoding service
        $areas = [
            ['name' => 'South Mumbai', 'lat' => 18.9067, 'lon' => 72.8147, 'radius' => 10],
            ['name' => 'Central Mumbai', 'lat' => 19.0176, 'lon' => 72.8562, 'radius' => 8],
            ['name' => 'North Mumbai', 'lat' => 19.2183, 'lon' => 72.9781, 'radius' => 12],
            ['name' => 'Connaught Place', 'lat' => 28.6315, 'lon' => 77.2167, 'radius' => 5],
            ['name' => 'Gurgaon', 'lat' => 28.4595, 'lon' => 77.0266, 'radius' => 15],
            ['name' => 'Whitefield', 'lat' => 12.9698, 'lon' => 77.7500, 'radius' => 10],
            ['name' => 'Koramangala', 'lat' => 12.9279, 'lon' => 77.6271, 'radius' => 8],
        ];

        foreach ($areas as $area) {
            $distance = $this->haversineDistance(
                $latitude,
                $longitude,
                $area['lat'],
                $area['lon']
            );

            if ($distance <= $area['radius']) {
                return $area['name'];
            }
        }

        return null;
    }
}