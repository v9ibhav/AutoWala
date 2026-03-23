<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Google Maps API Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for Google Maps Platform APIs used in AutoWala
    |
    */

    'api_key' => env('GOOGLE_MAPS_API_KEY'),

    'places_api_key' => env('GOOGLE_PLACES_API_KEY', env('GOOGLE_MAPS_API_KEY')),

    'endpoints' => [
        'geocoding' => 'https://maps.googleapis.com/maps/api/geocode/json',
        'directions' => 'https://maps.googleapis.com/maps/api/directions/json',
        'distance_matrix' => 'https://maps.googleapis.com/maps/api/distancematrix/json',
        'places_autocomplete' => 'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        'places_details' => 'https://maps.googleapis.com/maps/api/place/details/json',
        'roads_nearest' => 'https://roads.googleapis.com/v1/nearestRoads',
    ],

    'default_params' => [
        'language' => 'en',
        'region' => 'IN',
        'components' => 'country:IN',
    ],

    'rate_limiting' => [
        'requests_per_minute' => 600,
        'requests_per_day' => 25000,
    ],

    'cache' => [
        'geocoding_ttl' => 7200, // 2 hours
        'directions_ttl' => 1800, // 30 minutes
        'places_ttl' => 3600,    // 1 hour
    ],

    'indian_cities' => [
        'mumbai' => ['lat' => 19.0760, 'lon' => 72.8777],
        'delhi' => ['lat' => 28.7041, 'lon' => 77.1025],
        'bangalore' => ['lat' => 12.9716, 'lon' => 77.5946],
        'hyderabad' => ['lat' => 17.3850, 'lon' => 78.4867],
        'pune' => ['lat' => 18.5204, 'lon' => 73.8567],
        'kolkata' => ['lat' => 22.5726, 'lon' => 88.3639],
        'chennai' => ['lat' => 13.0827, 'lon' => 80.2707],
        'ahmedabad' => ['lat' => 23.0225, 'lon' => 72.5714],
        'surat' => ['lat' => 21.1702, 'lon' => 72.8311],
        'jaipur' => ['lat' => 26.9124, 'lon' => 75.7873],
    ],
];