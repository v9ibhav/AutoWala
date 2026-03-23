<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Firebase Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for Firebase services used in AutoWala
    |
    */

    'project_id' => env('FIREBASE_PROJECT_ID', 'autowala-ride-discovery'),

    'database_url' => env('FIREBASE_DATABASE_URL', 'https://autowala-ride-discovery-default-rtdb.asia-southeast1.firebasedatabase.app/'),

    'credentials' => env('FIREBASE_CREDENTIALS', storage_path('app/private/firebase-service-account.json')),

    'realtime' => [
        'active_riders' => 'active_riders',
        'active_rides' => 'active_rides',
        'rider_sessions' => 'rider_sessions',
        'notifications' => 'notifications',
    ],

    'fcm' => [
        'server_key' => env('FIREBASE_SERVER_KEY'),
        'sender_id' => env('FIREBASE_SENDER_ID'),
    ],

    'settings' => [
        'location_update_interval' => 5, // seconds
        'session_timeout' => 3600, // 1 hour
        'max_concurrent_sessions' => 1,
    ],
];