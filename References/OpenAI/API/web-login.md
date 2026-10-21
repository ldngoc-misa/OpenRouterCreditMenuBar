Request
```bash
curl --url 'https://api.openai.com/v1/dashboard/onboarding/login' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9,vi;q=0.8' \
  -H 'authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6InFBZ2JmZ3VSbjFRTzMycU5PV0hLTnJGS01Pd1NldzFUYW1GWlBDSTc4SFEiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOlsiaHR0cHM6Ly9hcGkub3BlbmFpLmNvbS92MSJdLCJjbGllbnRfaWQiOiJhcHBfMlNLeDY3RWRwb04wRzZqNjRyRnZpZ1hEIiwiaHR0cHM6Ly9hcGkub3BlbmFpLmNvbS9hdXRoIjp7ImFtciI6WyJ1cm46b3BlbmFpOmFtcjptaWNyb3NvZnQiXSwiY2hhdGdwdF9jb21wdXRlX3Jlc2lkZW5jeSI6Im5vX2NvbnN0cmFpbnQiLCJjaGF0Z3B0X2RhdGFfcmVzaWRlbmN5Ijoibm9fY29uc3RyYWludCIsInVzZXJfaWQiOiJ1c2VyLW5kVmhCVlNodHBGVFdHQVJ2ZlhPR1dHWiJ9LCJodHRwczovL2FwaS5vcGVuYWkuY29tL3Byb2ZpbGUiOnsiZW1haWwiOiJuZ29jbGU0OTJAb3V0bG9vay5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibmFtZSI6Ik5nXHUxZWNkYyBMXHUwMGVhIn0sImlzcyI6Imh0dHBzOi8vYXV0aC5vcGVuYWkuY29tIiwicHdkX2F1dGhfdGltZSI6MTc4OTAwMzYzNDg3MCwic2NwIjpbIm9wZW5pZCIsImVtYWlsIiwicHJvZmlsZSIsIm9mZmxpbmVfYWNjZXNzIl0sInNlc3Npb25faWQiOiJhdXRoc2Vzc196RzlMTVRheFdjbUxXcWk2N2c5SmN4bjkiLCJzbCI6dHJ1ZSwic3ViIjoid2luZG93c2xpdmV8OGQyNTU4YzNhMjAzZjY1MyIsImlhdCI6MTc5MjA2MDQ5NSwiZXhwIjoxNzkyOTI0NDk1LCJqdGkiOiI3YjJhMDdhMTk0ZTI0ZmUxODFmNDRmOWFkZWFhYmZiNyIsIm5iZiI6MTc5MjA2MDQ5NX0.HaknKUdBB1T3rxJanWpOoWr73m9tvIMV7i0SizZsu6PaUjcj7CzsqQ58KfwuYb7sI_UYQnxcQWoRA2R7V2XGwwTXfP7ReHkalAxGqpCm3znCi4rv159Mi0Zel9cJIKqu2o6JLxPyT4liDSGQulj68qKIL7RCILVd2pCKyOvkNee8g6_8EomcHy4z4hGPl4p0Xk02IAKa9nW5KbiK5-QeYUs0bMUgLnPOuuIDf3NMQO56ec2-cIwhpNPawIn-WrIkjdYa2cgBURT4XHP0EE8F9VyCRMC2NBe6lutcB8sdyyE1ZRgKeu1AUiHx6mfEtkQinrHBCd6XY7OLzxxxoa_eeg' \
  -H 'content-type: application/json' \
  -H 'origin: https://platform.openai.com' \
  -H 'priority: u=1, i' \
  -H 'referer: https://platform.openai.com/' \
  -H 'sec-ch-ua: "Microsoft Edge";v="155", "Chromium";v="155", "Not(A:Brand";v="24"' \
  -H 'sec-ch-ua-mobile: ?1' \
  -H 'sec-ch-ua-platform: "Android"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 16; Pixel 10) AppleWebKit/537.36 (KHTML, like Gecko) Edg/155.0.0.0 Mobile Safari/537.36' \
  --data-raw '{"app":"api"}'
```

Response
```json
{
  "object": "login",
  "user": {
    "object": "user",
    "id": "user-ndVhBVShtpFTWGARvfXOGWGZ",
    "email": "ngocle492@outlook.com",
    "name": "Ngọc Lê",
    "picture": null,
    "created": 1760413882,
    "phone_number": null,
    "mfa_flag_enabled": true,
    "email_domain_type": "social",
    "ads_segment_id": 1946,
    "cookie_consent": {
      "is_required": false
    },
    "groups": [],
    "session": {
      "sensitive_id": "sess-wJAdFjBY1uucZhfzOm3dK3T5VH9lxn0veGskCOfY",
      "object": "api_key",
      "name": null,
      "created": 1792560664,
      "expires_at": null,
      "last_use": null,
      "deleted_at": null,
      "publishable": false,
      "tracking_id": "key_ig3zXNg9c7k1EBHd",
      "scopes": null,
      "organization": null,
      "enabled": true,
      "project": null,
      "user": null
    },
    "orgs": {
      "object": "list",
      "data": [
        {
          "object": "organization",
          "id": "org-1Q5GrXvvNEeKeV9UToXnXOGB",
          "created": 1760413882,
          "title": "Personal",
          "name": "user-ndvhbvshtpftwgarvfxogwgz",
          "description": "Personal org for ngocle492@outlook.com",
          "personal": true,
          "settings": {
            "threads_ui_visibility": "NONE",
            "usage_dashboard_visibility": "ANY_ROLE",
            "disable_user_api_keys": false,
            "allowed_service_tiers": null,
            "completed_platform_onboarding": false,
            "store_completions_default": "ENABLED_OFF",
            "feedback_collection_permission": "ANY_ROLE",
            "share_api_data_permission": "ANY_ROLE",
            "share_evals_permission": "DEFAULT",
            "logs_ui_visibility": "OWNERS",
            "share_eval_ft_data": "ANY_ROLE"
          },
          "parent_org_id": null,
          "is_default": true,
          "role": "owner",
          "is_scale_tier_authorized_purchaser": false,
          "is_scim_managed": false,
          "projects": {
            "object": "list",
            "data": [
              {
                "object": "project",
                "id": "proj_JYaAgBd2I0ZiOgVRG7LU45Tv",
                "title": "Default project",
                "created": 1789528971,
                "archived_at": null,
                "organization_id": "org-1Q5GrXvvNEeKeV9UToXnXOGB",
                "is_initial": true,
                "geography": null,
                "residency": "GLOBAL",
                "scale_tier_enabled": false,
                "fast_tier_enabled": false,
                "allowed_service_tiers": null,
                "organization_allowed_service_tiers": null,
                "disable_user_api_keys": false,
                "feedback_collection_permission": "ANY_ROLE",
                "share_api_data_permission": "ANY_ROLE",
                "store_completions_default": "ENABLED_OFF",
                "share_evals_permission": "DEFAULT",
                "share_eval_ft_data": "ANY_ROLE",
                "logs_ui_visibility": "OWNERS",
                "zdr_type": null,
                "eyes_off_enabled": null,
                "role": "owner"
              }
            ],
            "has_more": false
          },
          "groups": [],
          "geography": null,
          "auth_access": {
            "allowed": true,
            "status": "unknown"
          }
        }
      ]
    },
    "has_payg_project_spend_limit": true,
    "intercom_hash": "fdb45ab4a7b870b62da82fca8fa1d98d1b296cbca6f4f8192b9fe79809856bf2",
    "amr": []
  },
  "invites": [],
  "arkose_enabled": false,
  "ip_country": "VN",
  "age_verification": {
    "is_required": false
  },
  "authentication_method_reference_context": {
    "method": "other",
    "sso_connection_id": null
  }
}
```