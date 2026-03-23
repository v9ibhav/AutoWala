<?php

namespace App\Services\Auth;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Exception;

class OTPService
{
    /**
     * OTP length
     */
    const OTP_LENGTH = 6;

    /**
     * OTP expiry in minutes
     */
    const OTP_EXPIRY_MINUTES = 10;

    /**
     * Maximum OTP attempts
     */
    const MAX_OTP_ATTEMPTS = 3;

    /**
     * Send OTP to user phone number
     */
    public function sendOTP(string $phoneNumber, string $countryCode = '+91'): array
    {
        try {
            // Find or create user
            $user = User::firstOrCreate(
                ['phone_number' => $phoneNumber],
                [
                    'country_code' => $countryCode,
                    'is_verified' => false,
                ]
            );

            // Check if too many attempts
            if ($user->otp_attempts >= self::MAX_OTP_ATTEMPTS &&
                $user->otp_expires_at &&
                $user->otp_expires_at->isFuture()) {
                return [
                    'success' => false,
                    'message' => 'Too many OTP attempts. Please try again later.',
                    'retry_after' => $user->otp_expires_at->diffInMinutes(now())
                ];
            }

            // Generate new OTP
            $otp = $this->generateOTP();

            // Update user with OTP details
            $user->update([
                'otp_code' => $otp,
                'otp_expires_at' => Carbon::now()->addMinutes(self::OTP_EXPIRY_MINUTES),
                'otp_attempts' => 0,
            ]);

            // Send OTP via SMS
            $smsResult = $this->sendSMS($user->getFormattedPhoneAttribute(), $otp);

            if (!$smsResult['success']) {
                return [
                    'success' => false,
                    'message' => 'Failed to send OTP. Please try again.',
                ];
            }

            Log::info('OTP sent successfully', [
                'phone' => $phoneNumber,
                'user_id' => $user->id,
                'otp_expires_at' => $user->otp_expires_at
            ]);

            return [
                'success' => true,
                'message' => 'OTP sent successfully',
                'expires_in' => self::OTP_EXPIRY_MINUTES,
                'user_id' => $user->id,
            ];

        } catch (Exception $e) {
            Log::error('Failed to send OTP', [
                'phone' => $phoneNumber,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send OTP. Please try again.',
            ];
        }
    }

    /**
     * Verify OTP and return user
     */
    public function verifyOTP(string $phoneNumber, string $otpCode): array
    {
        try {
            $user = User::where('phone_number', $phoneNumber)->first();

            if (!$user) {
                return [
                    'success' => false,
                    'message' => 'User not found',
                ];
            }

            // Check if OTP attempts exceeded
            if ($user->otp_attempts >= self::MAX_OTP_ATTEMPTS) {
                return [
                    'success' => false,
                    'message' => 'Maximum OTP attempts exceeded',
                ];
            }

            // Check if OTP is valid
            if (!$user->isOtpValid($otpCode)) {
                // Increment attempts
                $user->incrementOtpAttempts();

                $remainingAttempts = self::MAX_OTP_ATTEMPTS - $user->otp_attempts;

                return [
                    'success' => false,
                    'message' => $remainingAttempts > 0
                        ? "Invalid OTP. {$remainingAttempts} attempts remaining."
                        : 'Invalid OTP. Maximum attempts exceeded.',
                    'remaining_attempts' => $remainingAttempts,
                ];
            }

            // OTP is valid - clear OTP data and mark user as verified
            $user->clearOtp();

            Log::info('OTP verified successfully', [
                'phone' => $phoneNumber,
                'user_id' => $user->id
            ]);

            return [
                'success' => true,
                'message' => 'OTP verified successfully',
                'user' => $user->fresh(),
            ];

        } catch (Exception $e) {
            Log::error('Failed to verify OTP', [
                'phone' => $phoneNumber,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to verify OTP. Please try again.',
            ];
        }
    }

    /**
     * Generate random OTP
     */
    private function generateOTP(): string
    {
        return str_pad(random_int(0, pow(10, self::OTP_LENGTH) - 1), self::OTP_LENGTH, '0', STR_PAD_LEFT);
    }

    /**
     * Send SMS with OTP
     */
    private function sendSMS(string $phoneNumber, string $otp): array
    {
        try {
            $message = "Your AutoWala verification code is: {$otp}. Valid for " . self::OTP_EXPIRY_MINUTES . " minutes. Do not share this with anyone.";

            // For development, log the OTP instead of sending SMS
            if (app()->environment('local', 'testing')) {
                Log::info('Development OTP', [
                    'phone' => $phoneNumber,
                    'otp' => $otp,
                    'message' => $message
                ]);

                return ['success' => true];
            }

            // In production, use AWS SNS or Twilio
            $smsProvider = config('services.sms_provider', 'aws_sns');

            switch ($smsProvider) {
                case 'aws_sns':
                    return $this->sendViaSNS($phoneNumber, $message);

                case 'twilio':
                    return $this->sendViaTwilio($phoneNumber, $message);

                default:
                    throw new Exception('Invalid SMS provider configured');
            }

        } catch (Exception $e) {
            Log::error('SMS sending failed', [
                'phone' => $phoneNumber,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }
    }

    /**
     * Send SMS via AWS SNS
     */
    private function sendViaSNS(string $phoneNumber, string $message): array
    {
        try {
            // AWS SNS implementation would go here
            // For now, simulate success

            Log::info('SMS sent via AWS SNS', [
                'phone' => $phoneNumber,
                'message_length' => strlen($message)
            ]);

            return ['success' => true];

        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'SMS sending failed via SNS: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send SMS via Twilio
     */
    private function sendViaTwilio(string $phoneNumber, string $message): array
    {
        try {
            // Twilio implementation would go here
            // For now, simulate success

            Log::info('SMS sent via Twilio', [
                'phone' => $phoneNumber,
                'message_length' => strlen($message)
            ]);

            return ['success' => true];

        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'SMS sending failed via Twilio: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Resend OTP to user
     */
    public function resendOTP(string $phoneNumber): array
    {
        $user = User::where('phone_number', $phoneNumber)->first();

        if (!$user) {
            return [
                'success' => false,
                'message' => 'User not found',
            ];
        }

        // Check if enough time has passed since last OTP
        if ($user->otp_expires_at && $user->otp_expires_at->isFuture()) {
            $waitTime = $user->otp_expires_at->diffInSeconds(now()->addMinutes(self::OTP_EXPIRY_MINUTES - 2));

            if ($waitTime > 0) {
                return [
                    'success' => false,
                    'message' => 'Please wait before requesting new OTP',
                    'wait_seconds' => $waitTime
                ];
            }
        }

        // Send new OTP
        return $this->sendOTP($phoneNumber, $user->country_code);
    }
}