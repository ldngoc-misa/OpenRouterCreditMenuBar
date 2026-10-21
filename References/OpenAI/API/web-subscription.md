Request
```bash
curl --url 'https://api.openai.com/v1/dashboard/billing/subscription' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9,vi;q=0.8' \
  -H 'authorization: Bearer sess-wJAdFjBY1uucZhfzOm3dK3T5VH9lxn0veGskCOfY' \
  -H 'openai-organization: org-1Q5GrXvvNEeKeV9UToXnXOGB' \
  -H 'origin: https://platform.openai.com' \
  -H 'priority: u=1, i' \
  -H 'referer: https://platform.openai.com/' \
  -H 'sec-ch-ua: "Microsoft Edge";v="155", "Chromium";v="155", "Not(A:Brand";v="24"' \
  -H 'sec-ch-ua-mobile: ?1' \
  -H 'sec-ch-ua-platform: "Android"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 16; Pixel 10) AppleWebKit/537.36 (KHTML, like Gecko) Edg/155.0.0.0 Mobile Safari/537.36'
```

Response
```json
{
  "object": "billing_subscription",
  "has_payment_method": true,
  "canceled": false,
  "canceled_at": null,
  "delinquent": null,
  "access_until": 1797465600,
  "soft_limit": null,
  "hard_limit": null,
  "system_hard_limit": 1666666667,
  "soft_limit_usd": null,
  "hard_limit_usd": null,
  "system_hard_limit_usd": 100000.00001999999,
  "plan": {
    "title": "Pay-as-you-go",
    "id": "payg"
  },
  "subscription_title": "Pay-as-you-go",
  "primary": true,
  "billing_page_enabled": true,
  "billing_mechanism": "advance",
  "is_arrears_eligible": false,
  "max_balance": 500,
  "auto_recharge_eligible": true,
  "auto_recharge_enabled": true,
  "auto_recharge_threshold": 500,
  "auto_recharge_to_balance": 1000,
  "is_admin_extended_access": false,
  "trust_tier": "tier2",
  "is_limits_enforced": true,
  "is_legacy_budget_limits_deprecated": true,
  "api_key_cost_filtering_available_from": "2026-09-16T00:22:52.554496+00:00",
  "hard_limit_enforcement_available_from": "2026-09-16T00:22:52.554496+00:00",
  "account_name": "Ngọc Lê",
  "po_number": null,
  "billing_email": "ngocle492@outlook.com",
  "tax_ids": null,
  "billing_address": {
    "city": "Hanoi",
    "country": "VN",
    "line1": "Số 3226, Tòa S2.02, KĐT Vinhomes Smart City, Phường Tây Mỗ, Quận Nam Từ Liêm, Thành phố Hà Nội",
    "line2": null,
    "postal_code": "10000",
    "state": "Hanoi City"
  },
  "business_address": null,
  "auto_recharge_settings": {
    "is_enabled": true,
    "recharge_threshold_cents": 500,
    "recharge_target_cents": 1000,
    "recharge_limit_cents": 2000,
    "backup_payment_method_enabled": null
  },
  "monthly_billing_usage_alert": {
    "has_access_to_alerts": true,
    "alert_threshold": "100",
    "alerts": [
      {
        "alert_id": "M2ddEKASsWugZndG2tVpEPlH",
        "threshold_percent": "100",
        "email_recipients": [],
        "current_month_alerted": false,
        "email_subject_prefix": ""
      },
      {
        "alert_id": "X7EqRKm4uYOXMlYPmG0GhYjM",
        "threshold_percent": "80",
        "email_recipients": [],
        "current_month_alerted": false,
        "email_subject_prefix": ""
      }
    ]
  },
  "is_invoice_credit_eligible": false,
  "organization_hard_limit_enforcing": false,
  "prepaid_migration": null
}
```