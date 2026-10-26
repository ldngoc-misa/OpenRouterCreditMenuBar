Request
```bash
curl --url 'https://api.openai.com/v1/dashboard/organization/costs?bucket_width=1d&end_time=1793059200&limit=31&start_time=1792454400' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9,vi;q=0.8' \
  -H 'authorization: Bearer sess-HJvfk7EJ8HsPmUSKopmQYbWPvgmZb2z0KPNhxtCp' \
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
  "object": "page",
  "data": [
    {
      "object": "bucket",
      "end_time": 1792540800,
      "end_time_iso": "2026-10-21T00:00:00+00:00",
      "results": [],
      "start_time": 1792454400,
      "start_time_iso": "2026-10-20T00:00:00+00:00"
    },
    {
      "object": "bucket",
      "end_time": 1792627200,
      "end_time_iso": "2026-10-22T00:00:00",
      "results": [
        {
          "object": "organization.costs.result",
          "amount": {
            "currency": "usd",
            "value": 0.2128278750000000000000000000
          },
          "api_key_id": null,
          "api_source": null,
          "line_item": null,
          "organization_id": "org-1Q5GrXvvNEeKeV9UToXnXOGB",
          "organization_name": "Personal",
          "project_id": null,
          "project_name": null,
          "quantity": null,
          "quantity_unit": null,
          "user_email": null,
          "user_id": null
        }
      ],
      "start_time": 1792540800,
      "start_time_iso": "2026-10-21T00:00:00"
    },
    {
      "object": "bucket",
      "end_time": 1792713600,
      "end_time_iso": "2026-10-23T00:00:00+00:00",
      "results": [],
      "start_time": 1792627200,
      "start_time_iso": "2026-10-22T00:00:00+00:00"
    },
    {
      "object": "bucket",
      "end_time": 1792800000,
      "end_time_iso": "2026-10-24T00:00:00+00:00",
      "results": [],
      "start_time": 1792713600,
      "start_time_iso": "2026-10-23T00:00:00+00:00"
    },
    {
      "object": "bucket",
      "end_time": 1792886400,
      "end_time_iso": "2026-10-25T00:00:00+00:00",
      "results": [],
      "start_time": 1792800000,
      "start_time_iso": "2026-10-24T00:00:00+00:00"
    },
    {
      "object": "bucket",
      "end_time": 1792972800,
      "end_time_iso": "2026-10-26T00:00:00+00:00",
      "results": [],
      "start_time": 1792886400,
      "start_time_iso": "2026-10-25T00:00:00+00:00"
    },
    {
      "object": "bucket",
      "end_time": 1793059200,
      "end_time_iso": "2026-10-27T00:00:00",
      "results": [
        {
          "object": "organization.costs.result",
          "amount": {
            "currency": "usd",
            "value": 1.196111140000000000000000000
          },
          "api_key_id": null,
          "api_source": null,
          "line_item": null,
          "organization_id": "org-1Q5GrXvvNEeKeV9UToXnXOGB",
          "organization_name": "Personal",
          "project_id": null,
          "project_name": null,
          "quantity": null,
          "quantity_unit": null,
          "user_email": null,
          "user_id": null
        }
      ],
      "start_time": 1792972800,
      "start_time_iso": "2026-10-26T00:00:00"
    }
  ],
  "has_more": false,
  "next_page": null
}
```