<?php

namespace App\Services\Firebase;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Database;
use Kreait\Firebase\Exception\FirebaseException;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

class RealtimeService
{
    protected Database $database;
    protected array $config;

    /**
     * Initialize Firebase Realtime Database
     */
    public function __construct()
    {
        try {
            $this->config = config('firebase');

            $firebase = (new Factory)
                ->withServiceAccount($this->config['credentials'])
                ->withDatabaseUri($this->config['database_url']);

            $this->database = $firebase->createDatabase();

        } catch (\Exception $e) {
            Log::critical('Failed to initialize Firebase Realtime Database', [
                'error' => $e->getMessage(),
                'config_path' => $this->config['credentials'] ?? 'not_configured'
            ]);

            throw $e;
        }
    }

    /**
     * Update rider location in real-time
     */
    public function updateRiderLocation(
        int $riderId,
        float $latitude,
        float $longitude,
        ?int $heading = null,
        ?int $accuracy = null,
        ?array $additionalData = []
    ): bool {
        try {
            $locationData = array_merge([
                'rider_id' => $riderId,
                'lat' => $latitude,
                'lon' => $longitude,
                'heading' => $heading ?? 0,
                'accuracy' => $accuracy ?? 10,
                'timestamp' => now()->timestamp * 1000, // Firebase expects milliseconds
                'last_update' => ['.sv' => 'timestamp'], // Server timestamp
                'status' => 'online',
            ], $additionalData);

            $reference = $this->database->getReference($this->config['realtime']['active_riders'] . '/' . $riderId);
            $reference->update($locationData);

            Log::debug('Rider location updated in Firebase', [
                'rider_id' => $riderId,
                'location' => [$latitude, $longitude],
                'heading' => $heading
            ]);

            // Also cache locally for quick access
            Cache::put("rider_location:{$riderId}", $locationData, 300); // 5 minutes cache

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to update rider location in Firebase', [
                'rider_id' => $riderId,
                'location' => [$latitude, $longitude],
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Remove rider from active riders
     */
    public function removeRiderFromActive(int $riderId): bool
    {
        try {
            $reference = $this->database->getReference($this->config['realtime']['active_riders'] . '/' . $riderId);
            $reference->remove();

            // Remove from local cache
            Cache::forget("rider_location:{$riderId}");

            Log::info('Rider removed from active riders', ['rider_id' => $riderId]);

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to remove rider from active riders', [
                'rider_id' => $riderId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Create ride session for real-time tracking
     */
    public function createRideSession(
        int $rideLogId,
        array $rideData,
        string $sessionId = null
    ): ?string {
        try {
            $sessionId = $sessionId ?? $this->generateSessionId($rideLogId);

            $rideSessionData = array_merge([
                'ride_log_id' => $rideLogId,
                'user_id' => $rideData['user_id'],
                'rider_id' => $rideData['rider_id'],
                'status' => 'in_transit',
                'pickup_lat' => $rideData['pickup_lat'] ?? null,
                'pickup_lon' => $rideData['pickup_lon'] ?? null,
                'dropoff_lat' => $rideData['dropoff_lat'] ?? null,
                'dropoff_lon' => $rideData['dropoff_lon'] ?? null,
                'current_rider_lat' => null,
                'current_rider_lon' => null,
                'eta_pickup_sec' => null,
                'eta_dropoff_sec' => null,
                'created_at' => ['.sv' => 'timestamp'],
                'timestamp' => now()->timestamp * 1000,
            ], $rideData);

            $reference = $this->database->getReference($this->config['realtime']['active_rides'] . '/' . $rideLogId);
            $reference->set($rideSessionData);

            Log::info('Ride session created in Firebase', [
                'ride_log_id' => $rideLogId,
                'session_id' => $sessionId,
                'user_id' => $rideData['user_id'],
                'rider_id' => $rideData['rider_id']
            ]);

            return $sessionId;

        } catch (FirebaseException $e) {
            Log::error('Failed to create ride session in Firebase', [
                'ride_log_id' => $rideLogId,
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Update ride session data
     */
    public function updateRideSession(int $rideLogId, array $updateData): bool
    {
        try {
            $updateData['timestamp'] = now()->timestamp * 1000;
            $updateData['last_update'] = ['.sv' => 'timestamp'];

            $reference = $this->database->getReference($this->config['realtime']['active_rides'] . '/' . $rideLogId);
            $reference->update($updateData);

            Log::debug('Ride session updated in Firebase', [
                'ride_log_id' => $rideLogId,
                'update_keys' => array_keys($updateData)
            ]);

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to update ride session in Firebase', [
                'ride_log_id' => $rideLogId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * End ride session
     */
    public function endRideSession(int $rideLogId): bool
    {
        try {
            $reference = $this->database->getReference($this->config['realtime']['active_rides'] . '/' . $rideLogId);
            $reference->remove();

            Log::info('Ride session ended in Firebase', ['ride_log_id' => $rideLogId]);

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to end ride session in Firebase', [
                'ride_log_id' => $rideLogId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Get active riders in an area
     */
    public function getActiveRidersInArea(
        float $centerLat,
        float $centerLon,
        float $radiusKm = 5
    ): array {
        try {
            $cacheKey = "firebase_riders:{$centerLat}:{$centerLon}:{$radiusKm}";

            return Cache::remember($cacheKey, 30, function () use ($centerLat, $centerLon, $radiusKm) {
                $reference = $this->database->getReference($this->config['realtime']['active_riders']);
                $snapshot = $reference->getSnapshot();

                if (!$snapshot->exists()) {
                    return [];
                }

                $activeRiders = [];
                $allRiders = $snapshot->getValue();

                foreach ($allRiders as $riderId => $riderData) {
                    if (!isset($riderData['lat']) || !isset($riderData['lon'])) {
                        continue;
                    }

                    // Calculate distance using Haversine formula
                    $distance = $this->calculateDistance(
                        $centerLat,
                        $centerLon,
                        $riderData['lat'],
                        $riderData['lon']
                    );

                    if ($distance <= $radiusKm) {
                        $activeRiders[] = [
                            'rider_id' => $riderId,
                            'latitude' => $riderData['lat'],
                            'longitude' => $riderData['lon'],
                            'heading' => $riderData['heading'] ?? 0,
                            'accuracy' => $riderData['accuracy'] ?? 10,
                            'distance_km' => round($distance, 2),
                            'last_update' => $riderData['timestamp'] ?? null,
                            'status' => $riderData['status'] ?? 'unknown',
                            'additional_data' => array_diff_key($riderData, [
                                'lat' => true,
                                'lon' => true,
                                'heading' => true,
                                'accuracy' => true,
                                'timestamp' => true,
                                'last_update' => true,
                                'status' => true,
                                'rider_id' => true
                            ])
                        ];
                    }
                }

                // Sort by distance
                usort($activeRiders, fn($a, $b) => $a['distance_km'] <=> $b['distance_km']);

                return $activeRiders;
            });

        } catch (FirebaseException $e) {
            Log::error('Failed to get active riders from Firebase', [
                'center' => [$centerLat, $centerLon],
                'radius_km' => $radiusKm,
                'error' => $e->getMessage()
            ]);

            return [];
        }
    }

    /**
     * Get ride session data
     */
    public function getRideSession(int $rideLogId): ?array
    {
        try {
            $reference = $this->database->getReference($this->config['realtime']['active_rides'] . '/' . $rideLogId);
            $snapshot = $reference->getSnapshot();

            if (!$snapshot->exists()) {
                return null;
            }

            return $snapshot->getValue();

        } catch (FirebaseException $e) {
            Log::error('Failed to get ride session from Firebase', [
                'ride_log_id' => $rideLogId,
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Start rider session (when going online)
     */
    public function startRiderSession(
        int $riderId,
        array $riderInfo,
        array $routeIds = []
    ): bool {
        try {
            $sessionData = array_merge([
                'rider_id' => $riderId,
                'session_id' => $this->generateSessionId($riderId, 'rider'),
                'start_time' => ['.sv' => 'timestamp'],
                'is_active' => true,
                'routes_serving' => $routeIds,
                'timestamp' => now()->timestamp * 1000,
            ], $riderInfo);

            $reference = $this->database->getReference($this->config['realtime']['rider_sessions'] . '/' . $riderId);
            $reference->set($sessionData);

            Log::info('Rider session started in Firebase', [
                'rider_id' => $riderId,
                'routes_count' => count($routeIds)
            ]);

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to start rider session in Firebase', [
                'rider_id' => $riderId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * End rider session (when going offline)
     */
    public function endRiderSession(int $riderId): bool
    {
        try {
            // Remove from rider sessions
            $sessionRef = $this->database->getReference($this->config['realtime']['rider_sessions'] . '/' . $riderId);
            $sessionRef->remove();

            // Remove from active riders
            $this->removeRiderFromActive($riderId);

            Log::info('Rider session ended in Firebase', ['rider_id' => $riderId]);

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to end rider session in Firebase', [
                'rider_id' => $riderId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Send real-time notification
     */
    public function sendRealtimeNotification(
        string $channel,
        array $notificationData
    ): bool {
        try {
            $notificationData['timestamp'] = now()->timestamp * 1000;
            $notificationData['sent_at'] = ['.sv' => 'timestamp'];

            $reference = $this->database->getReference($this->config['realtime']['notifications'] . '/' . $channel);
            $reference->push($notificationData);

            Log::debug('Real-time notification sent via Firebase', [
                'channel' => $channel,
                'type' => $notificationData['type'] ?? 'unknown'
            ]);

            return true;

        } catch (FirebaseException $e) {
            Log::error('Failed to send real-time notification via Firebase', [
                'channel' => $channel,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Batch update multiple rider locations
     */
    public function batchUpdateRiderLocations(array $locationUpdates): array
    {
        $successCount = 0;
        $failures = [];

        try {
            $updates = [];

            foreach ($locationUpdates as $update) {
                $riderId = $update['rider_id'];
                $path = $this->config['realtime']['active_riders'] . '/' . $riderId;

                $updates[$path] = [
                    'rider_id' => $riderId,
                    'lat' => $update['latitude'],
                    'lon' => $update['longitude'],
                    'heading' => $update['heading'] ?? 0,
                    'accuracy' => $update['accuracy'] ?? 10,
                    'timestamp' => now()->timestamp * 1000,
                    'last_update' => ['.sv' => 'timestamp'],
                    'status' => 'online',
                ];
            }

            // Perform batch update
            $this->database->getReference()->update($updates);

            $successCount = count($locationUpdates);

            Log::info('Batch updated rider locations in Firebase', [
                'count' => $successCount
            ]);

        } catch (FirebaseException $e) {
            Log::error('Failed to batch update rider locations in Firebase', [
                'count' => count($locationUpdates),
                'error' => $e->getMessage()
            ]);

            $failures = array_map(function ($update) use ($e) {
                return [
                    'rider_id' => $update['rider_id'],
                    'error' => $e->getMessage()
                ];
            }, $locationUpdates);
        }

        return [
            'successful_updates' => $successCount,
            'failed_updates' => count($failures),
            'failures' => $failures,
        ];
    }

    /**
     * Clean up stale data
     */
    public function cleanupStaleData(int $timeoutMinutes = 10): array
    {
        $cleaned = ['riders' => 0, 'sessions' => 0];

        try {
            $staleTimestamp = (now()->subMinutes($timeoutMinutes))->timestamp * 1000;

            // Clean up stale active riders
            $ridersRef = $this->database->getReference($this->config['realtime']['active_riders']);
            $ridersSnapshot = $ridersRef->getSnapshot();

            if ($ridersSnapshot->exists()) {
                foreach ($ridersSnapshot->getValue() as $riderId => $riderData) {
                    $lastUpdate = $riderData['timestamp'] ?? 0;

                    if ($lastUpdate < $staleTimestamp) {
                        $ridersRef->getChild($riderId)->remove();
                        $cleaned['riders']++;
                    }
                }
            }

            // Clean up stale rider sessions
            $sessionsRef = $this->database->getReference($this->config['realtime']['rider_sessions']);
            $sessionsSnapshot = $sessionsRef->getSnapshot();

            if ($sessionsSnapshot->exists()) {
                foreach ($sessionsSnapshot->getValue() as $riderId => $sessionData) {
                    $startTime = $sessionData['timestamp'] ?? 0;

                    if ($startTime < $staleTimestamp) {
                        $sessionsRef->getChild($riderId)->remove();
                        $cleaned['sessions']++;
                    }
                }
            }

            Log::info('Cleaned up stale Firebase data', $cleaned);

        } catch (FirebaseException $e) {
            Log::error('Failed to cleanup stale Firebase data', [
                'error' => $e->getMessage()
            ]);
        }

        return $cleaned;
    }

    /**
     * Generate unique session ID
     */
    private function generateSessionId(int $entityId, string $type = 'ride'): string
    {
        return "{$type}_session_" . $entityId . '_' . now()->timestamp . '_' . bin2hex(random_bytes(4));
    }

    /**
     * Calculate distance using Haversine formula
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
     * Get Firebase database reference
     */
    public function getReference(string $path = ''): \Kreait\Firebase\Database\Reference
    {
        return $this->database->getReference($path);
    }

    /**
     * Test Firebase connection
     */
    public function testConnection(): bool
    {
        try {
            $testRef = $this->database->getReference('test/connection');
            $testRef->set(['timestamp' => now()->timestamp, 'test' => true]);
            $testRef->remove();

            return true;

        } catch (FirebaseException $e) {
            Log::error('Firebase connection test failed', ['error' => $e->getMessage()]);
            return false;
        }
    }
}