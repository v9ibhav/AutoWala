<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserRating extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'from_user_id',
        'to_rider_id',
        'ride_log_id',
        'rating',
        'feedback',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * Get the user who gave the rating
     */
    public function fromUser()
    {
        return $this->belongsTo(User::class, 'from_user_id');
    }

    /**
     * Get the rider who received the rating
     */
    public function toRider()
    {
        return $this->belongsTo(Rider::class, 'to_rider_id');
    }

    /**
     * Get the ride this rating is for
     */
    public function rideLog()
    {
        return $this->belongsTo(RideLog::class);
    }

    /**
     * Validation rules for rating
     */
    public static function rules(): array
    {
        return [
            'rating' => 'required|integer|min:1|max:5',
            'feedback' => 'nullable|string|max:500',
            'ride_log_id' => 'required|exists:ride_logs,id',
            'to_rider_id' => 'required|exists:riders,id',
        ];
    }

    /**
     * Get rating display text
     */
    public function getRatingTextAttribute(): string
    {
        $ratingTexts = [
            1 => 'Poor',
            2 => 'Fair',
            3 => 'Good',
            4 => 'Very Good',
            5 => 'Excellent',
        ];

        return $ratingTexts[$this->rating] ?? 'Unknown';
    }

    /**
     * Scope for high ratings (4-5 stars)
     */
    public function scopeHighRating($query)
    {
        return $query->whereIn('rating', [4, 5]);
    }

    /**
     * Scope for low ratings (1-2 stars)
     */
    public function scopeLowRating($query)
    {
        return $query->whereIn('rating', [1, 2]);
    }
}