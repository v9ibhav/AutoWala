<?php

namespace App\Services\Auth;

use App\Models\User;
use App\Models\Rider;
use App\Models\Admin;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Exception;

class JWTService
{
    /**
     * Generate JWT token for user
     */
    public function generateTokenForUser(User $user): array
    {
        try {
            $token = JWTAuth::fromUser($user);

            return [
                'success' => true,
                'token' => $token,
                'token_type' => 'bearer',
                'expires_in' => config('jwt.ttl') * 60, // Convert minutes to seconds
                'user' => $this->formatUserData($user),
            ];

        } catch (JWTException $e) {
            Log::error('JWT token generation failed for user', [
                'user_id' => $user->id,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Could not create token',
            ];
        }
    }

    /**
     * Generate JWT token for rider
     */
    public function generateTokenForRider(Rider $rider): array
    {
        try {
            // Use the rider's associated user for JWT
            $user = $rider->user;
            $token = JWTAuth::fromUser($user);

            return [
                'success' => true,
                'token' => $token,
                'token_type' => 'bearer',
                'expires_in' => config('jwt.ttl') * 60,
                'rider' => $this->formatRiderData($rider),
                'user' => $this->formatUserData($user),
            ];

        } catch (JWTException $e) {
            Log::error('JWT token generation failed for rider', [
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Could not create token',
            ];
        }
    }

    /**
     * Generate JWT token for admin
     */
    public function generateTokenForAdmin(Admin $admin): array
    {
        try {
            // For admin, we use a different guard/provider
            $token = auth('admin')->login($admin);

            return [
                'success' => true,
                'token' => $token,
                'token_type' => 'bearer',
                'expires_in' => config('jwt.ttl') * 60,
                'admin' => $this->formatAdminData($admin),
            ];

        } catch (JWTException $e) {
            Log::error('JWT token generation failed for admin', [
                'admin_id' => $admin->id,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Could not create token',
            ];
        }
    }

    /**
     * Refresh JWT token
     */
    public function refreshToken(): array
    {
        try {
            $token = JWTAuth::refresh();
            $user = JWTAuth::setToken($token)->toUser();

            return [
                'success' => true,
                'token' => $token,
                'token_type' => 'bearer',
                'expires_in' => config('jwt.ttl') * 60,
                'user' => $this->formatUserData($user),
            ];

        } catch (JWTException $e) {
            Log::error('JWT token refresh failed', [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Could not refresh token',
            ];
        }
    }

    /**
     * Invalidate JWT token
     */
    public function invalidateToken(): array
    {
        try {
            JWTAuth::invalidate();

            return [
                'success' => true,
                'message' => 'Successfully logged out',
            ];

        } catch (JWTException $e) {
            Log::error('JWT token invalidation failed', [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Could not invalidate token',
            ];
        }
    }

    /**
     * Get authenticated user from token
     */
    public function getAuthenticatedUser(): ?User
    {
        try {
            return JWTAuth::parseToken()->authenticate();

        } catch (JWTException $e) {
            Log::info('JWT authentication failed', [
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Validate token
     */
    public function validateToken(?string $token = null): array
    {
        try {
            if ($token) {
                JWTAuth::setToken($token);
            }

            $user = JWTAuth::parseToken()->authenticate();

            if (!$user) {
                return [
                    'valid' => false,
                    'message' => 'User not found',
                ];
            }

            return [
                'valid' => true,
                'user' => $this->formatUserData($user),
                'expires_at' => $this->getTokenExpirationTime(),
            ];

        } catch (JWTException $e) {
            return [
                'valid' => false,
                'message' => 'Token is invalid',
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Get token expiration time
     */
    public function getTokenExpirationTime(): ?Carbon
    {
        try {
            $payload = JWTAuth::getPayload();
            $exp = $payload->get('exp');

            return $exp ? Carbon::createFromTimestamp($exp) : null;

        } catch (Exception $e) {
            return null;
        }
    }

    /**
     * Check if token is expired
     */
    public function isTokenExpired(): bool
    {
        try {
            $expirationTime = $this->getTokenExpirationTime();
            return $expirationTime ? $expirationTime->isPast() : true;

        } catch (Exception $e) {
            return true;
        }
    }

    /**
     * Format user data for response
     */
    private function formatUserData(User $user): array
    {
        return [
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
        ];
    }

    /**
     * Format rider data for response
     */
    private function formatRiderData(Rider $rider): array
    {
        return [
            'id' => $rider->id,
            'full_name' => $rider->full_name,
            'phone_number' => $rider->phone_number,
            'kyc_status' => $rider->kyc_status,
            'average_rating' => $rider->average_rating,
            'total_rides' => $rider->total_rides,
            'is_online' => $rider->is_online,
            'fare_per_passenger' => $rider->fare_per_passenger,
            'vehicle' => $rider->vehicle ? [
                'id' => $rider->vehicle->id,
                'registration_number' => $rider->vehicle->registration_number,
                'make' => $rider->vehicle->make,
                'model' => $rider->vehicle->model,
                'color' => $rider->vehicle->color,
                'max_passengers' => $rider->vehicle->max_passengers,
            ] : null,
            'has_active_routes' => $rider->hasActiveRoutes(),
        ];
    }

    /**
     * Format admin data for response
     */
    private function formatAdminData(Admin $admin): array
    {
        return [
            'id' => $admin->id,
            'full_name' => $admin->full_name,
            'email' => $admin->email,
            'role' => $admin->role,
            'permissions' => $admin->permissions,
            'last_login_at' => $admin->last_login_at,
        ];
    }

    /**
     * Generate custom claims for token
     */
    public function generateCustomClaims(User $user, array $additionalClaims = []): array
    {
        $claims = [
            'user_id' => $user->id,
            'phone' => $user->phone_number,
            'verified' => $user->is_verified,
            'iat' => now()->timestamp,
            'exp' => now()->addMinutes(config('jwt.ttl'))->timestamp,
        ];

        return array_merge($claims, $additionalClaims);
    }

    /**
     * Create token with custom payload
     */
    public function createTokenWithCustomClaims(User $user, array $customClaims = []): array
    {
        try {
            $claims = $this->generateCustomClaims($user, $customClaims);
            $token = JWTAuth::claims($claims)->fromUser($user);

            return [
                'success' => true,
                'token' => $token,
                'custom_claims' => $claims,
            ];

        } catch (JWTException $e) {
            return [
                'success' => false,
                'message' => 'Could not create token with custom claims',
            ];
        }
    }
}