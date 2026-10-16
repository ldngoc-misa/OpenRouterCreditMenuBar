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
        "description": "DeepSeek V4.1 Flash is a sparse mixture-of-experts model from DeepSeek, and the first built on the company's Causal Encoder-Decoder (CED) architecture. It activates 8B parameters on input and 16B on output from a 552B-parameter backbone, an asymmetric split that keeps per-token compute low relative to the model's total size. Image understanding is native to the architecture, with visual and text embeddings trained jointly from the start of pre-training rather than added afterward as in the earlier experimental [V4 Flash Vision Exp](https://openrouter.ai/deepseek/deepseek-v4-flash-vision-exp).\n\nIt is suited for coding, terminal, and computer-use agents, along with long-horizon tasks that must run to completion across many steps and long-context analysis. Compressed KV caching cuts cache memory to roughly a quarter of the previous Flash generation, significantly reducing costs on agentic workloads. DeepSeek positions it as the cost-efficient tier of the V4.1 family and reports that it exceeds [V4 Pro](https://openrouter.ai/deepseek/deepseek-v4-pro-0813) on performance, speed, and task completion time.",
        "model_version_group_id": "3786fc1c-4a67-4934-bd3f-ab4f98a63a72",
        "context_length": 1048576,
        "input_modalities": [
          "text"
        ],
        "output_modalities": [
          "text"
        ],
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
          "start_token": "<think>",
          "end_token": "</think>",
          "is_mandatory_reasoning": false,
          "supports_reasoning_effort": true,
          "supported_reasoning_efforts": [
            "high"
          ],
          "default_reasoning_effort": "high",
          "default_reasoning_enabled": true,
          "reasoning_return_mechanism": "reasoning-content"
        },
        "features": {
          "reasoning_config": {
            "start_token": "<think>",
            "end_token": "</think>",
            "is_mandatory_reasoning": false,
            "supports_reasoning_effort": true,
            "supported_reasoning_efforts": [
              "high"
            ],
            "default_reasoning_effort": "high",
            "default_reasoning_enabled": true,
            "reasoning_return_mechanism": "reasoning-content"
          },
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
          "id": "014281e2-a692-4f9a-9ee5-9ba5d6a0d53f",
          "name": "OpenInference | deepseek/deepseek-v4.1-flash-20260910",
          "context_length": 1048576,
          "model": {
            "slug": "deepseek/deepseek-v4.1-flash",
            "hf_slug": "deepseek-ai/DeepSeek-V4.1-Flash",
            "updated_at": "2026-09-14T15:19:10.881948+00:00",
            "created_at": "2026-09-10T06:21:25.18+00:00",
            "hf_updated_at": null,
            "name": "DeepSeek: DeepSeek V4.1 Flash",
            "short_name": "DeepSeek V4.1 Flash",
            "author": "deepseek",
            "author_display_name": "DeepSeek",
            "author_icon_uri": null,
            "description": "DeepSeek V4.1 Flash is a sparse mixture-of-experts model from DeepSeek, and the first built on the company's Causal Encoder-Decoder (CED) architecture. It activates 8B parameters on input and 16B on output from a 552B-parameter backbone, an asymmetric split that keeps per-token compute low relative to the model's total size. Image understanding is native to the architecture, with visual and text embeddings trained jointly from the start of pre-training rather than added afterward as in the earlier experimental [V4 Flash Vision Exp](https://openrouter.ai/deepseek/deepseek-v4-flash-vision-exp).\n\nIt is suited for coding, terminal, and computer-use agents, along with long-horizon tasks that must run to completion across many steps and long-context analysis. Compressed KV caching cuts cache memory to roughly a quarter of the previous Flash generation, significantly reducing costs on agentic workloads. DeepSeek positions it as the cost-efficient tier of the V4.1 family and reports that it exceeds [V4 Pro](https://openrouter.ai/deepseek/deepseek-v4-pro-0813) on performance, speed, and task completion time.",
            "model_version_group_id": "3786fc1c-4a67-4934-bd3f-ab4f98a63a72",
            "context_length": 1048576,
            "input_modalities": [
              "text"
            ],
            "output_modalities": [
              "text"
            ],
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
              "start_token": "<think>",
              "end_token": "</think>",
              "is_mandatory_reasoning": false,
              "supports_reasoning_effort": true,
              "supported_reasoning_efforts": [
                "high"
              ],
              "default_reasoning_effort": "high",
              "default_reasoning_enabled": true,
              "reasoning_return_mechanism": "reasoning-content"
            },
            "features": {
              "reasoning_config": {
                "start_token": "<think>",
                "end_token": "</think>",
                "is_mandatory_reasoning": false,
                "supports_reasoning_effort": true,
                "supported_reasoning_efforts": [
                  "high"
                ],
                "default_reasoning_effort": "high",
                "default_reasoning_enabled": true,
                "reasoning_return_mechanism": "reasoning-content"
              },
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
            "supported_tts_voices": null
          },
          "model_variant_slug": "deepseek/deepseek-v4.1-flash",
          "model_variant_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
          "adapter_name": "OpenInferenceAdapter",
          "provider_name": "OpenInference",
          "provider_info": {
            "name": "OpenInference",
            "displayName": "Open Inference",
            "slug": "open-inference",
            "baseUrl": "https://api.openinference.ai/v1",
            "dataPolicy": {
              "training": false,
              "trainingOpenRouter": false,
              "retainsPrompts": false,
              "canPublish": false,
              "termsOfServiceURL": "https://www.openinference.ai/terms",
              "privacyPolicyURL": "https://www.openinference.ai/privacy",
              "requiresUserIDs": false
            },
            "headquarters": "US",
            "hasChatCompletions": true,
            "hasCompletions": true,
            "isAbortable": true,
            "moderationRequired": false,
            "requiredAttestationTypes": [],
            "adapterName": "OpenInferenceAdapter",
            "statusPageUrl": null,
            "byokEnabled": true,
            "isPrivate": false,
            "icon": {
              "url": "https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://openinference.xyz/&size=256",
              "className": "invert dark:invert-0"
            },
            "sendClientIp": false,
            "pricingStrategy": "openai_chat_completions"
          },
          "provider_permaslug": "open-inference",
          "provider_display_name": "Open Inference",
          "provider_slug": "open-inference/fp4",
          "derived_service_tier": null,
          "provider_model_id": "deepseek-ai/DeepSeek-V4.1-Flash",
          "quantization": "fp4",
          "variant": "standard",
          "is_free": false,
          "can_abort": true,
          "max_prompt_tokens": null,
          "max_completion_tokens": 1048576,
          "max_tokens_per_image": null,
          "supported_parameters": [
            "reasoning"
          ],
          "excluded_parameters": [],
          "is_byok": false,
          "moderation_required": false,
          "data_policy": {
            "training": false,
            "trainingOpenRouter": false,
            "retainsPrompts": false,
            "canPublish": false,
            "termsOfServiceURL": "https://www.openinference.ai/terms",
            "privacyPolicyURL": "https://www.openinference.ai/privacy"
          },
          "pricing": {
            "prompt": "0.0000000144",
            "completion": "0.000000684",
            "input_cache_read": "0.0000000054",
            "discount": 0,
            "display_pricing": [
              {
                "kind": "token",
                "sku_label": "Input Price",
                "price": "0.0000000144",
                "displayMultiplier": 1000000,
                "unitLabel": "/M tokens"
              }
            ]
          },
          "server_tool_costs_discount_exempt": true,
          "display_pricing": [
            {
              "kind": "token",
              "sku_label": "Input Price",
              "price": "0.0000000144",
              "displayMultiplier": 1000000,
              "unitLabel": "/M tokens"
            }
          ],
          "pricing_json": {
            "openai:prompt_tokens": "0.0000000144",
            "openai:completion_tokens": "0.000000684",
            "openai:cached_prompt_tokens": "0.0000000054"
          },
          "pricing_version_id": "855bc9a6-0ab3-4b87-8cff-f40378ad4f89",
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
          "has_completions": true,
          "has_chat_completions": true,
          "features": {
            "supports_tool_choice": {
              "literal_none": true,
              "literal_auto": true,
              "literal_required": true,
              "type_function": true
            }
          },
          "supported_video_parameters": null,
          "supported_image_parameters": null,
          "supported_stt_parameters": null,
          "provider_region": null,
          "declared_region": null,
          "deprecation_date": null,
          "allowed_passthrough_parameters": [],
          "capacity_tpm": null,
          "created_at": "2026-09-22T19:12:11.239Z",
          "status": 0
        },
        "display_required_attestation_types": [],
        "variant_deprecation_date": null
      }
    ],
    "analytics": {
      "deepseek/deepseek-v4.1-flash-20260910": {
        "date": "2026-10-09 00:00:00",
        "model_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
        "variant": "standard",
        "variant_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
        "count": 784588419,
        "total_completion_tokens": 768499551779,
        "total_prompt_tokens": 36625422673697,
        "total_native_tokens_reasoning": 499622723605,
        "num_media_prompt": 329265709,
        "num_media_completion": 0,
        "image_output_requests": 0,
        "num_video_prompt": 0,
        "video_output_seconds": 0,
        "rerank_documents": 0,
        "stt_transcript_characters": 0,
        "num_audio_prompt": 0,
        "total_native_tokens_cached": 33640169344191,
        "total_tool_calls": 318809496,
        "requests_with_tool_call_errors": 2623842,
        "total_byok_prompt_tokens": 1806093014112,
        "total_byok_completion_tokens": 36101127582
      },
      "deepseek/deepseek-v4.1-flash-20260910:batch": {
        "date": "2026-10-09 00:00:00",
        "model_permaslug": "deepseek/deepseek-v4.1-flash-20260910",
        "variant": "batch",
        "variant_permaslug": "deepseek/deepseek-v4.1-flash-20260910:batch",
        "count": 911475,
        "total_completion_tokens": 1264354334,
        "total_prompt_tokens": 3035450289,
        "total_native_tokens_reasoning": 803999671,
        "num_media_prompt": 0,
        "num_media_completion": 0,
        "image_output_requests": 0,
        "num_video_prompt": 0,
        "video_output_seconds": 0,
        "rerank_documents": 0,
        "stt_transcript_characters": 0,
        "num_audio_prompt": 0,
        "total_native_tokens_cached": 1463665792,
        "total_tool_calls": 2756,
        "requests_with_tool_call_errors": 0,
        "total_byok_prompt_tokens": 0,
        "total_byok_completion_tokens": 0
      }
    },
    "categories": {
      "deepseek/deepseek-v4.1-flash-20260910": [
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "academia",
          "count": 11907,
          "total_prompt_tokens": 141970871,
          "total_completion_tokens": 17149678,
          "volume": 18.456894,
          "rank": 1
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "finance",
          "count": 22430,
          "total_prompt_tokens": 1260629645,
          "total_completion_tokens": 26927878,
          "volume": 42.784804,
          "rank": 1
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "health",
          "count": 19262,
          "total_prompt_tokens": 85953554,
          "total_completion_tokens": 14058597,
          "volume": 14.784003,
          "rank": 2
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "legal",
          "count": 5657,
          "total_prompt_tokens": 95363922,
          "total_completion_tokens": 13469568,
          "volume": 13.099781,
          "rank": 2
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "marketing",
          "count": 3573,
          "total_prompt_tokens": 87069328,
          "total_completion_tokens": 3127322,
          "volume": 6.501148,
          "rank": 1
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "marketing/seo",
          "count": 444,
          "total_prompt_tokens": 13595135,
          "total_completion_tokens": 630801,
          "volume": 1.021723,
          "rank": 6
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "programming",
          "count": 302269,
          "total_prompt_tokens": 17581055940,
          "total_completion_tokens": 315595050,
          "volume": 679.50585,
          "rank": 1
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "roleplay",
          "count": 78852,
          "total_prompt_tokens": 758436284,
          "total_completion_tokens": 31384376,
          "volume": 49.575459,
          "rank": 2
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "science",
          "count": 45902,
          "total_prompt_tokens": 1662842471,
          "total_completion_tokens": 77935956,
          "volume": 109.967855,
          "rank": 2
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "technology",
          "count": 157586,
          "total_prompt_tokens": 5543459173,
          "total_completion_tokens": 188935839,
          "volume": 369.925167,
          "rank": 1
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "translation",
          "count": 15111,
          "total_prompt_tokens": 36968700,
          "total_completion_tokens": 17028342,
          "volume": 14.99792,
          "rank": 2
        },
        {
          "date": "2026-10-15",
          "model": "deepseek/deepseek-v4.1-flash-20260910",
          "category": "trivia",
          "count": 9778,
          "total_prompt_tokens": 25856460,
          "total_completion_tokens": 2270637,
          "volume": 2.947399,
          "rank": 1
        }
      ]
    },
    "modality_counts": {
      "decisions": 23
    },
    "benchmarks": {
      "deepseek/deepseek-v4.1-flash-20260910": {
        "aa": {
          "intelligence_index": 39.5,
          "coding_index": null,
          "agentic_index": null
        }
      }
    },
    "endpoint_perf": {
      "014281e2-a692-4f9a-9ee5-9ba5d6a0d53f": {
        "p50_latency": 2267,
        "p50_throughput": 20
      }
    },
    "benchmark_ranges": {
      "tool_success_rate": {
        "min": 0,
        "max": 1
      }
    }
  }
}

```
