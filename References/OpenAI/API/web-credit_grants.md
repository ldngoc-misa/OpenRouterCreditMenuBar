Request
```bash
curl --url 'https://api.openai.com/v1/dashboard/billing/credit_grants' \
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
  "object": "credit_summary",
  "total_granted": 20.0,
  "total_used": 0.0,
  "total_available": 20.0,
  "total_paid_available": 20.0,
  "grants": {
    "object": "list",
    "data": [
      {
        "object": "credit_summary",
        "id": "in_1UQm8LC6h1nxGoI3rE0hm0ZC",
        "grant_amount": 20.0,
        "used_amount": 0.0,
        "effective_at": 1792022400.0,
        "expires_at": 1825027200.0,
        "is_scheduled": false,
        "is_held_for_prepaid_transition": false
      }
    ]
  }
}
```