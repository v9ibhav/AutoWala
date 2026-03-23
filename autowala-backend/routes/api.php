<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Auth\AuthController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application.
| AutoWala - Production-Grade Ride Discovery Platform API Routes
|
*/

// API Health Check
Route::get('/health', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'AutoWala API is running',
        'version' => '1.0',
        'timestamp' => now()->toISOString(),
        'environment' => app()->environment(),
    ]);
});

// API Version Info
Route::get('/version', function () {
    return response()->json([
        'api_version' => '1.0',
        'application' => 'AutoWala',
        'description' => 'Production-Grade Ride Discovery Platform',
        'documentation' => 'https://api.autowala.in/docs',
        'support' => 'support@autowala.in',
    ]);
});

/*
|--------------------------------------------------------------------------
| Authentication Routes
|--------------------------------------------------------------------------
*/

Route::prefix('auth')->group(function () {
    // Public authentication routes (no middleware)
    Route::post('/send-otp', [AuthController::class, 'sendOTP'])
        ->name('auth.send-otp')
        ->middleware(['throttle:5,1']); // 5 requests per minute

    Route::post('/verify-otp', [AuthController::class, 'verifyOTP'])
        ->name('auth.verify-otp')
        ->middleware(['throttle:10,1']); // 10 requests per minute

    Route::post('/resend-otp', [AuthController::class, 'resendOTP'])
        ->name('auth.resend-otp')
        ->middleware(['throttle:3,1']); // 3 requests per minute

    Route::post('/validate-token', [AuthController::class, 'validateToken'])
        ->name('auth.validate-token')
        ->middleware(['throttle:20,1']); // 20 requests per minute

    // Protected authentication routes (require JWT token)
    Route::middleware(['auth:api'])->group(function () {
        Route::post('/refresh', [AuthController::class, 'refreshToken'])
            ->name('auth.refresh');

        Route::post('/logout', [AuthController::class, 'logout'])
            ->name('auth.logout');

        Route::get('/profile', [AuthController::class, 'profile'])
            ->name('auth.profile');
    });
});

/*
|--------------------------------------------------------------------------
| User Routes (Protected)
|--------------------------------------------------------------------------
| All user routes require authentication
*/

Route::middleware(['auth:api'])->prefix('user')->group(function () {
    // Profile Management
    Route::get('/profile', function (Request $request) {
        return response()->json([
            'message' => 'User profile endpoint - Implementation pending',
            'user' => $request->user(),
        ]);
    })->name('user.profile');

    // Placeholder for other user routes
    Route::get('/ride-history', function () {
        return response()->json(['message' => 'Ride history endpoint - Implementation pending']);
    })->name('user.ride-history');

    Route::post('/complaint', function () {
        return response()->json(['message' => 'Complaint submission endpoint - Implementation pending']);
    })->name('user.complaint');
});

/*
|--------------------------------------------------------------------------
| Ride Discovery Routes (Protected)
|--------------------------------------------------------------------------
*/

Route::middleware(['auth:api'])->prefix('rides')->group(function () {
    // Ride Discovery
    Route::post('/search-nearby', function () {
        return response()->json(['message' => 'Nearby rides search endpoint - Implementation pending']);
    })->name('rides.search-nearby')
      ->middleware(['throttle:60,1']); // 60 requests per minute

    Route::get('/rider/{id}/details', function ($id) {
        return response()->json(['message' => "Rider {$id} details endpoint - Implementation pending"]);
    })->name('rides.rider-details');

    Route::post('/book', function () {
        return response()->json(['message' => 'Ride booking endpoint - Implementation pending']);
    })->name('rides.book');

    Route::get('/{id}/track', function ($id) {
        return response()->json(['message' => "Ride {$id} tracking endpoint - Implementation pending"]);
    })->name('rides.track');

    Route::post('/{id}/rating', function ($id) {
        return response()->json(['message' => "Ride {$id} rating endpoint - Implementation pending"]);
    })->name('rides.rating');
});

/*
|--------------------------------------------------------------------------
| Rider Routes (Protected)
|--------------------------------------------------------------------------
| Routes specifically for auto-rickshaw drivers
*/

Route::middleware(['auth:api'])->prefix('rider')->group(function () {
    // Registration & Profile
    Route::post('/register', function () {
        return response()->json(['message' => 'Rider registration endpoint - Implementation pending']);
    })->name('rider.register');

    Route::get('/profile', function () {
        return response()->json(['message' => 'Rider profile endpoint - Implementation pending']);
    })->name('rider.profile');

    // KYC Management
    Route::post('/kyc-documents', function () {
        return response()->json(['message' => 'KYC documents upload endpoint - Implementation pending']);
    })->name('rider.kyc-documents');

    Route::get('/kyc-status', function () {
        return response()->json(['message' => 'KYC status endpoint - Implementation pending']);
    })->name('rider.kyc-status');

    // Route Management
    Route::get('/routes', function () {
        return response()->json(['message' => 'Rider routes list endpoint - Implementation pending']);
    })->name('rider.routes.index');

    Route::post('/routes', function () {
        return response()->json(['message' => 'Create rider route endpoint - Implementation pending']);
    })->name('rider.routes.store');

    // Live Operations
    Route::post('/go-online', function () {
        return response()->json(['message' => 'Go online endpoint - Implementation pending']);
    })->name('rider.go-online');

    Route::post('/go-offline', function () {
        return response()->json(['message' => 'Go offline endpoint - Implementation pending']);
    })->name('rider.go-offline');

    Route::post('/location-update', function () {
        return response()->json(['message' => 'Location update endpoint - Implementation pending']);
    })->name('rider.location-update')
      ->middleware(['throttle:120,1']); // 120 requests per minute for location updates
});

/*
|--------------------------------------------------------------------------
| Admin Routes (Protected)
|--------------------------------------------------------------------------
| Administrative routes for platform management
*/

Route::middleware(['auth:admin'])->prefix('admin')->group(function () {
    // Dashboard
    Route::get('/dashboard', function () {
        return response()->json(['message' => 'Admin dashboard endpoint - Implementation pending']);
    })->name('admin.dashboard');

    // User Management
    Route::get('/users', function () {
        return response()->json(['message' => 'Users list endpoint - Implementation pending']);
    })->name('admin.users.index');

    Route::get('/users/{id}', function ($id) {
        return response()->json(['message' => "User {$id} details endpoint - Implementation pending"]);
    })->name('admin.users.show');

    // Rider Management
    Route::get('/riders', function () {
        return response()->json(['message' => 'Riders list endpoint - Implementation pending']);
    })->name('admin.riders.index');

    Route::put('/riders/{id}/kyc-status', function ($id) {
        return response()->json(['message' => "Update rider {$id} KYC status endpoint - Implementation pending"]);
    })->name('admin.riders.kyc-status');

    // Support & Analytics
    Route::get('/tickets', function () {
        return response()->json(['message' => 'Support tickets endpoint - Implementation pending']);
    })->name('admin.tickets.index');

    Route::get('/metrics/daily', function () {
        return response()->json(['message' => 'Daily metrics endpoint - Implementation pending']);
    })->name('admin.metrics.daily');
});

/*
|--------------------------------------------------------------------------
| Development Routes (Only in local/testing environments)
|--------------------------------------------------------------------------
*/

if (app()->environment(['local', 'testing'])) {
    Route::prefix('dev')->group(function () {
        Route::get('/routes', function () {
            $routes = collect(Route::getRoutes())->map(function ($route) {
                return [
                    'method' => implode('|', $route->methods()),
                    'uri' => $route->uri(),
                    'name' => $route->getName(),
                    'middleware' => $route->gatherMiddleware(),
                ];
            });

            return response()->json([
                'total_routes' => $routes->count(),
                'routes' => $routes->values(),
            ]);
        });

        Route::get('/config', function () {
            return response()->json([
                'app_name' => config('app.name'),
                'app_env' => config('app.env'),
                'database_connection' => config('database.default'),
                'cache_driver' => config('cache.default'),
                'jwt_ttl' => config('jwt.ttl'),
                'firebase_project' => config('firebase.project_id'),
            ]);
        });
    });
}