<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Notification extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'rider_id',
        'notification_type',
        'title',
        'message',
        'related_ride_log_id',
        'data',
        'is_read',
        'read_at',
        'fcm_message_id',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'data' => 'json',
            'is_read' => 'boolean',
            'read_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    /**
     * Notification types
     */
    const TYPE_AUTO_NEARBY = 'auto_nearby';
    const TYPE_RIDE_STARTED = 'ride_started';
    const TYPE_ETA_UPDATE = 'eta_update';
    const TYPE_RIDER_ARRIVED = 'rider_arrived';
    const TYPE_RIDE_COMPLETED = 'ride_completed';
    const TYPE_RIDE_CANCELLED = 'ride_cancelled';
    const TYPE_RATING_REQUEST = 'rating_request';
    const TYPE_KYC_APPROVED = 'kyc_approved';
    const TYPE_KYC_REJECTED = 'kyc_rejected';
    const TYPE_ACCOUNT_SUSPENDED = 'account_suspended';

    /**
     * Get the user this notification belongs to
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the rider this notification belongs to
     */
    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    /**
     * Get the related ride log
     */
    public function relatedRideLog()
    {
        return $this->belongsTo(RideLog::class, 'related_ride_log_id');
    }

    /**
     * Mark notification as read
     */
    public function markAsRead(): bool
    {
        if ($this->is_read) {
            return true;
        }

        return $this->update([
            'is_read' => true,
            'read_at' => now(),
        ]);
    }

    /**
     * Mark notification as unread
     */
    public function markAsUnread(): bool
    {
        return $this->update([
            'is_read' => false,
            'read_at' => null,
        ]);
    }

    /**
     * Create notification for user
     */
    public static function createForUser(
        int $userId,
        string $type,
        string $title,
        string $message,
        ?int $relatedRideLogId = null,
        ?array $data = null
    ): self {
        return self::create([
            'user_id' => $userId,
            'notification_type' => $type,
            'title' => $title,
            'message' => $message,
            'related_ride_log_id' => $relatedRideLogId,
            'data' => $data,
        ]);
    }

    /**
     * Create notification for rider
     */
    public static function createForRider(
        int $riderId,
        string $type,
        string $title,
        string $message,
        ?int $relatedRideLogId = null,
        ?array $data = null
    ): self {
        return self::create([
            'rider_id' => $riderId,
            'notification_type' => $type,
            'title' => $title,
            'message' => $message,
            'related_ride_log_id' => $relatedRideLogId,
            'data' => $data,
        ]);
    }

    /**
     * Get time ago for notification
     */
    public function getTimeAgoAttribute(): string
    {
        return $this->created_at->diffForHumans();
    }

    /**
     * Check if notification is recent (within 24 hours)
     */
    public function isRecent(): bool
    {
        return $this->created_at->isAfter(now()->subDay());
    }

    /**
     * Scope for unread notifications
     */
    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    /**
     * Scope for read notifications
     */
    public function scopeRead($query)
    {
        return $query->where('is_read', true);
    }

    /**
     * Scope for user notifications
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope for rider notifications
     */
    public function scopeForRider($query, int $riderId)
    {
        return $query->where('rider_id', $riderId);
    }

    /**
     * Scope for specific notification type
     */
    public function scopeOfType($query, string $type)
    {
        return $query->where('notification_type', $type);
    }

    /**
     * Scope for recent notifications
     */
    public function scopeRecent($query, int $days = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
}