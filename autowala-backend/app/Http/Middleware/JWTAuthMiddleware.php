<?php

namespace App\Http\Middleware;

use Closure;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Services\JWTService;

class JWTAuthMiddleware
{
    protected $jwtService;

    public function __construct(JWTService $jwtService)
    {
        $this->jwtService = $jwtService;
    }

    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\JsonResponse)  $next
     * @param  string|null  $guard
     * @return \Illuminate\Http\JsonResponse
     */
    public function handle(Request $request, Closure $next, $guard = null)
    {
        try {
            $token = $request->bearerToken();

            if (!$token) {
                return response()->json([
                    'success' => false,
                    'message' => 'Authorization token not provided'
                ], 401);
            }

            $payload = $this->jwtService->decode($token);

            if (!$payload) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid or expired token'
                ], 401);
            }

            // Set the user based on guard
            $this->setUserFromPayload($payload, $guard);

            return $next($request);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized: ' . $e->getMessage()
            ], 401);
        }
    }

    /**
     * Set the authenticated user based on the guard
     *
     * @param array $payload
     * @param string|null $guard
     * @return void
     */
    protected function setUserFromPayload($payload, $guard = null)
    {
        $userId = $payload['sub'] ?? null;

        if (!$userId) {
            throw new Exception('Invalid token payload');
        }

        switch ($guard) {
            case 'rider':
                $user = \App\Models\Rider::find($userId);
                break;
            case 'admin':
                $user = \App\Models\Admin::find($userId);
                break;
            default:
                $user = \App\Models\User::find($userId);
                break;
        }

        if (!$user) {
            throw new Exception('User not found');
        }

        auth()->setUser($user);
    }
}