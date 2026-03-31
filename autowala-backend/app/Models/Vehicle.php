<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Vehicle extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'rider_id',
        'registration_number',
        'make',
        'model',
        'color',
        'year',
        'max_passengers',
        'registration_doc_url',
        'insurance_doc_url',
        'insurance_number',
        'insurance_expiry',
        'pollution_certificate_url',
        'is_verified',
        'verification_status',
        'verification_notes',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'max_passengers' => 'integer',
            'insurance_expiry' => 'date',
            'is_verified' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    /**
     * Get the rider that owns the vehicle
     */
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    /**
     * Get the ride history for this vehicle
     */
    public function rideHistory()
    {
        return $this->hasMany(RideLog::class);
    }

    /**
     * Scope for verified vehicles
     */
    public function scopeVerified($query)
    {
        return $query->where('is_verified', true);
    }

    /**
     * Get display name for the vehicle
     */
    public function getDisplayNameAttribute(): string
    {
        $parts = array_filter([
            $this->make,
            $this->model,
            $this->color,
            $this->registration_number,
        ]);

        return implode(' ', $parts) ?: 'Auto Rickshaw';
    }

    /**
     * Get formatted registration number
     */
    public function getFormattedRegistrationAttribute(): string
    {
        return strtoupper($this->registration_number);
    }

    /**
     * Check if vehicle has all required documents
     */
    public function hasCompleteDocumentation(): bool
    {
        return !empty($this->registration_doc_url) &&
               !empty($this->insurance_doc_url) &&
               !empty($this->pollution_certificate_url);
    }

    /**
     * Accessor for 'capacity' field (controllers expect 'capacity' but model has 'max_passengers')
     */
    public function getCapacityAttribute(): int
    {
        return $this->max_passengers;
    }

    /**
     * Check if insurance is valid (not expired)
     */
    public function hasValidInsurance(): bool
    {
        return $this->insurance_expiry && $this->insurance_expiry->isFuture();
    }

    /**
     * Check if vehicle is approved
     */
    public function isApproved(): bool
    {
        return $this->verification_status === 'approved';
    }

    /**
     * Scope for approved vehicles
     */
    public function scopeApproved($query)
    {
        return $query->where('verification_status', 'approved');
    }

    /**
     * Scope for vehicles with valid insurance
     */
    public function scopeWithValidInsurance($query)
    {
        return $query->where('insurance_expiry', '>', now()->toDateString());
    }
}