Request
```bash
curl 'https://openrouter.ai/api/frontend/v1/models/find?active=true&fmt=cards&order=top-weekly' \
  -H 'accept: */*'
```

Response
```json
{
    "data": {
        "models": [
            {
                "slug": "deepseek/deepseek-v4.1-flash",
                "hf_slug": "deepseek-ai/DeepSeek-V4.1-Flash",
                "updated_at": "2026-09-14T15:19:10.881Z",
                "created_at": "2026-09-10T06:21:25.180Z",
                "hf_updated_at": null,
                "name": "DeepSeek: DeepSeek V4.1 Flash",
                "short_name": "DeepSeek V4.1 Flash",
                "author": "deepseek",
                "author_display_name": "DeepSeek",
                "author_icon_uri": null,
                "description": "DeepSeek V4.1 Flash is a sparse mixture-of-experts model from DeepSeek...",
                "model_version_group_id": "3786fc1c-4a67-4934-bd3f-ab4f98a63a72",
                "context_length": 1048576,
                "input_modalities": ["text", "image"],
                "output_modalities": ["text"],
                "has_text_output": true,
                "group": "DeepSeek",
                "instruct_type": null,
                "default_system": null,
                "default_stops": [],
                "hidden": false,
                "router": null,
                "warning_message": null,
                "promotion_message": null,
                "routing_error_message": null,
                "required_attestation_types": [],
                "is_private": false,
                "permaslug": "deepseek/deepseek-v4.1-flash-20260910",
                "supports_reasoning": true,
                "reasoning_config": {
                    "start_token": "thinking",
                    "end_token": "final",
                    "is_mandatory_reasoning": false,
                    "supports_reasoning_effort": true,
                    "supports_reasoning_max_tokens": false,
                    "supported_reasoning_efforts": ["high", "max", "low"],
                    "default_reasoning_effort": "high",
                    "default_reasoning_enabled": true,
                    "reasoning_return_mechanism": "reasoning-content"
                },
                "features": {
                    "reasoning_config": { ... },
                    "chat_template_config": {}
                },
                "default_parameters": {},
                "default_order": [],
                "quick_start_example_type": "reasoning",
                "previews_by_modality": {},
                "preview_thumbnail_url": null,
                "preview_audio": null,
                "author_flagship_modalities": [],
                "is_trainable_text": true,
                "is_trainable_image": null,
                "knowledge_cutoff": null,
                "limit_rpm": 0,
                "limit_rpd": 0,
                "supported_tts_voices": null,
                "endpoint": {
                    "id": "c2a1fb64-77b5-4ecf-9e28-7d3b901a329f",
                    "name": "Relace | deepseek/deepseek-v4.1-flash-20260910",
                    "context_length": 1048576,
                    "model": { ... },
                    "model_variant_slug": "deepseek/deepseek-v4.1-flash",
                    "model_variant_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
                    "adapter_name": "VLLMOpenAIAdapter",
                    "provider_name": "Relace",
                    "provider_info": {
                        "name": "Relace",
                        "displayName": "Relace",
                        "slug": "relace",
                        "baseUrl": "https://models.relace.ai/v1",
                        "dataPolicy": {
                            "training": false,
                            "trainingOpenRouter": false,
                            "retainsPrompts": false,
                            "canPublish": false,
                            "termsOfServiceURL": "https://www.relace.ai/terms-of-use",
                            "privacyPolicyURL": "https://www.relace.ai/privacy-policy",
                            "requiresUserIDs": false
                        },
                        "datacenters": [],
                        "hasChatCompletions": true,
                        "hasCompletions": false,
                        "isAbortable": true,
                        "moderationRequired": false,
                        "requiredAttestationTypes": [],
                        "adapterName": "VLLMOpenAIAdapter",
                        "statusPageUrl": "https://status.relace.ai",
                        "byokEnabled": true,
                        "icon": { "url": "https://t0.gstatic.com/faviconV2?..." },
                        "sendClientIp": false,
                        "pricingStrategy": "openai_chat_completions"
                    },
                    "provider_display_name": "Relace",
                    "provider_slug": "relace",
                    "provider_model_id": "deepseek-ai/DeepSeek-V4.1-Flash",
                    "quantization": "unknown",
                    "variant": "standard",
                    "is_free": false,
                    "can_abort": true,
                    "max_prompt_tokens": null,
                    "max_completion_tokens": 1048576,
                    "max_tokens_per_image": null,
                    "supported_parameters": [
                        "reasoning", "include_reasoning", "temperature", "top_p", "top_k", "min_p",
                        "stop", "max_tokens", "logit_bias", "frequency_penalty", "presence_penalty",
                        "repetition_penalty", "tools", "tool_choice"
                    ],
                    "excluded_parameters": ["response_format"],
                    "is_byok": false,
                    "moderation_required": false,
                    "data_policy": { ... },
                    "pricing": {
                        "prompt": "0.000000003",
                        "completion": "0.0000024",
                        "input_cache_read": "0.000000003",
                        "discount": 0,
                        "display_pricing": [
                            { "kind": "token", "sku_label": "Input Price", "price": "0.000000003", "displayMultiplier": 1000000, "unitLabel": "/M tokens" },
                            { "kind": "token", "sku_label": "Output Price", "price": "0.0000024", "displayMultiplier": 1000000, "unitLabel": "/M tokens" },
                            { "kind": "token", "sku_label": "Cache Read", "price": "0.000000003", "displayMultiplier": 1000000, "unitLabel": "/M tokens" }
                        ]
                    },
                    "server_tool_costs_discount_exempt": true,
                    "display_pricing": [ ... ],
                    "pricing_json": {
                        "openai:prompt_tokens": "0.000000003",
                        "openai:completion_tokens": "0.0000024",
                        "openai:cached_prompt_tokens": "0.000000003"
                    },
                    "pricing_version_id": "1f40bf38-5f73-44ef-a57c-acdc92d14951",
                    "is_pricing_unresolved": false,
                    "is_hidden": false,
                    "is_private": false,
                    "is_byok_only": false,
                    "is_deranked": false,
                    "is_disabled": false,
                    "is_hipaa_eligible": false,
                    "supports_tool_parameters": true,
                    "supports_reasoning": true,
                    "supports_multipart": true,
                    "limit_rpm": null,
                    "limit_rpd": null,
                    "has_completions": false,
                    "has_chat_completions": true,
                    "features": { "supports_tool_choice": { "literal_none": false, "literal_auto": true, "literal_required": false, "type_function": false } },
                    "supported_video_parameters": null,
                    "supported_image_parameters": null,
                    "provider_region": null,
                    "declared_region": null,
                    "deprecation_date": null,
                    "allowed_passthrough_parameters": [],
                    "capacity_tpm": null,
                    "created_at": "2026-09-12T23:12:34.853Z",
                    "status": 0
                },
                "display_required_attestation_types": [],
                "variant_deprecation_date": null
            }
        ],
        "analytics": {
            "deepseek/deepseek-v4.1-flash-20260910": {
                "date": "2026-09-29 00:00:00",
                "model_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
                "variant": "standard",
                "variant_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
                "count": 21293668,
                "total_usage": 14764.924452,
                "total_completion_tokens": 2221390866,
                "total_prompt_tokens": 52483557105,
                "total_native_tokens_reasoning": 36240765,
                "num_media_prompt": 0,
                "num_media_completion": 0,
                "image_output_requests": 0,
                "num_video_prompt": 0,
                "video_output_seconds": 0,
                "rerank_documents": 0,
                "stt_transcript_characters": 0,
                "num_audio_prompt": 0,
                "total_native_tokens_cached": 0,
                "total_tool_calls": 0,
                "requests_with_tool_call_errors": 0,
                "total_byok_prompt_tokens": 0,
                "total_byok_completion_tokens": 0
            }
        },
        "categories": {
            "deepseek/deepseek-v4.1-flash-20260910": [
                { "date": "2026-10-05", "model": "deepseek/deepseek-v4.1-flash-20260910", "category": "programming", "count": 278793, "total_prompt_tokens": 19828820157, "total_completion_tokens": 278411782, "volume": 701.781316, "rank": 1 },
                { "date": "2026-10-05", "model": "deepseek/deepseek-v4.1-flash-20260910", "category": "technology", "count": 103522, "total_prompt_tokens": 4988169834, "total_completion_tokens": 94569761, "volume": 248.451442, "rank": 1 },
                { "date": "2026-10-05", "model": "deepseek/deepseek-v4.1-flash-20260910", "category": "science", "count": 33009, "total_prompt_tokens": 1754924296, "total_completion_tokens": 56941048, "volume": 104.855568, "rank": 2 }
            ]
        },
        "benchmark_ranges": {
            "intelligence_index": { "min": 3.8, "max": 57.6 },
            "tool_success_rate": { "min": 0, "max": 1 },
            "coding_index": { "min": 2.7, "max": 81.6 },
            "agentic_index": { "min": 0.1, "max": 57.9 },
            "da_elo": {
                "models-uicomponent": { "min": 774, "max": 1402 },
                "models-audiorealism": { "min": 861, "max": 1206 },
                "models-text-to-speech": { "min": 1128, "max": 1438 },
                "models-3d": { "min": 852, "max": 1491 },
                "models-codecategories": { "min": 795, "max": 1406 },
                "models-dataviz": { "min": 529, "max": 1395 },
                "models-gamedev": { "min": 786, "max": 1480 },
                "models-svg": { "min": 928, "max": 1334 },
                "models-website": { "min": 757, "max": 1364 },
                "models-graphicdesign": { "min": 1007, "max": 1423 },
                "models-image": { "min": 1066, "max": 1370 },
                "models-imageediting": { "min": 1057, "max": 1317 },
                "models-logo": { "min": 1060, "max": 1298 },
                "models-asciiart": { "min": 999, "max": 1360 }
            }
        }
    }
}
```