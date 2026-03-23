<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Database\Eloquent\SoftDeletes;
use Carbon\Carbon;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'phone_number',
        'country_code',
        'full_name',
        'profile_photo_url',
        'email',
        'preferred_language',
        'notification_enabled',
        'is_verified',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'otp_code',
        'otp_expires_at',
        'otp_attempts',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'phone_number_verified_at' => 'datetime',
            'verified_at' => 'datetime',
            'otp_expires_at' => 'datetime',
            'is_active' => 'boolean',
            'is_verified' => 'boolean',
            'notification_enabled' => 'boolean',
            'otp_attempts' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    /**
     * Get the identifier that will be stored in the subject claim of the JWT.
     *
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * Return a key value array, containing any custom claims to be added to the JWT.
     *
     * @return array
     */
    public function getJWTCustomClaims()
    {
        return [
            'user_type' => 'user',
            'phone' => $this->phone_number,
            'verified' => $this->is_verified,
        ];
    }

    /**
     * Get the user's rider profile if they are a rider
     */
    public function rider()
    {
        return $this->hasOne(Rider::class);
    }

    /**
     * Get the user's ride history
     */
    public function rideHistory()
    {
        return $this->hasMany(RideLog::class)->orderBy('created_at', 'desc');
    }

    /**
     * Get the user's ratings given to riders
     */
    public function ratingsGiven()
    {
        return $this->hasMany(UserRating::class, 'from_user_id');
    }

    /**
     * Get the user's complaints
     */
    public function complaints()
    {
        return $this->hasMany(UserComplaint::class);
    }

    /**
     * Get the user's notifications
     */
    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    /**
     * Check if user has an active/ongoing ride
     */
    public function hasActiveRide()
    {
        return $this->rideHistory()
            ->whereIn('status', ['matched', 'in_transit'])
            ->exists();
    }

    /**
     * Get user's current active ride
     */
    public function activeRide()
    {
        return $this->rideHistory()
            ->whereIn('status', ['matched', 'in_transit'])
            ->first();
    }

    /**
     * Check if OTP is valid
     */
    public function isOtpValid(string $otp): bool
    {
        return $this->otp_code === $otp
            && $this->otp_expires_at
            && $this->otp_expires_at->isFuture()
            && $this->otp_attempts < 3;
    }

    /**
     * Generate and set OTP
     */
    public function generateOtp(): string
    {
        $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        $this->update([
            'otp_code' => $otp,
            'otp_expires_at' => Carbon::now()->addMinutes(10),
            'otp_attempts' => 0,
        ]);

        return $otp;
    }

    /**
     * Increment OTP attempts
     */
    public function incrementOtpAttempts(): void
    {
        $this->increment('otp_attempts');
    }

    /**
     * Clear OTP data after successful verification
     */
    public function clearOtp(): void
    {
        $this->update([
            'otp_code' => null,
            'otp_expires_at' => null,
            'otp_attempts' => 0,
            'is_verified' => true,
            'verified_at' => Carbon::now(),
        ]);
    }

    /**
     * Scope for active users
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for verified users
     */
    public function scopeVerified($query)
    {
        return $query->where('is_verified', true);
    }

    /**
     * Get formatted phone number with country code
     */
    public function getFormattedPhoneAttribute(): string
    {
        return $this->country_code . $this->phone_number;
    }
}