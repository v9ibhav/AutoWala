<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'AutoWala API Server is running!',
        'version' => '1.0.0',
        'timestamp' => now()->toISOString()
    ]);
});

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'AutoWala Backend',
        'timestamp' => now()->toISOString(),
        'environment' => app()->environment()
    ]);
});