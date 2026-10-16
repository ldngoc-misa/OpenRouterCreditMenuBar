Request
```bash
curl 'https://openrouter.ai/api/frontend/v1/models/find?active=true&fmt=cards&order=top-weekly&variant=free'
```

Response
```json
{
  "data": {
    "models": [
      {
        "slug": "nvidia/nemotron-3-ultra-550b-a55b",
        "hf_slug": "nvidia/NVIDIA-Nemotron-3-Ultra-550B-A55B-BF16",
        "updated_at": "2026-06-04T13:45:46.170Z",
        "created_at": "2026-06-04T05:33:28.534Z",
        "hf_updated_at": null,
        "name": "NVIDIA: Nemotron 3 Ultra (free)",
        "short_name": "Nemotron 3 Ultra (free)",
        "author": "nvidia",
        "author_display_name": "Nvidia",
        "author_icon_uri": null,
        "description": "NVIDIA Nemotron 3 Ultra is an open frontier-reasoning and orchestration model from NVIDIA, with 55B active parameters out of 550B total (MoE). Built on a hybrid Transformer-Mamba mixture-of-experts architecture, it supports text input and output with a context window of up to 1M tokens. It is suited for long-running agentic workflows, including agent orchestration, coding agents, deep research, and complex enterprise tasks.\n\nIt is particularly strong at multi-step reasoning and planning, with high-throughput inference designed for high-volume agent pipelines. It is part of the NVIDIA Nemotron family of open models for agentic AI.",
        "model_version_group_id": null,
        "context_length": 1000000,
        "input_modalities": [
          "text"
        ],
        "output_modalities": [
          "text"
        ],
        "has_text_output": true,
        "group": "Other",
        "instruct_type": null,
        "default_system": null,
        "default_stops": [],
        "hidden": false,
        "router": null,
        "warning_message": "For the free endpoint, please do not upload any confidential information or personal data (such as voices or faces of people). Your use is logged for security purposes and to improve NVIDIA products and services. The logged session data for improvement purposes is not linked to your identity or any persistent identifier. For more information about NVIDIA's data processing practices, see [Privacy Policy](https://www.nvidia.com/en-us/about-nvidia/privacy-policy/). By using this free endpoint, you consent to NVIDIA's collection, recording, and use of such information and the [NVIDIA API Trial Terms of Service](https://assets.ngc.nvidia.com/products/api-catalog/legal/NVIDIA%20API%20Trial%20Terms%20of%20Service.pdf)",
        "promotion_message": null,
        "routing_error_message": null,
        "required_attestation_types": [],
        "is_private": false,
        "permaslug": "nvidia/nemotron-3-ultra-550b-a55b-20260604",
        "supports_reasoning": true,
        "reasoning_config": {
          "start_token": "<think>",
          "end_token": "</think>",
          "supports_reasoning_effort": true,
          "supports_reasoning_max_tokens": true,
          "supported_reasoning_efforts": [
            "medium"
          ],
          "default_reasoning_effort": "high",
          "default_reasoning_enabled": true,
          "reasoning_return_mechanism": "reasoning-content"
        },
        "features": {
          "reasoning_config": {
            "start_token": "<think>",
            "end_token": "</think>",
            "supports_reasoning_effort": true,
            "supports_reasoning_max_tokens": true,
            "supported_reasoning_efforts": [
              "medium"
            ],
            "default_reasoning_effort": "high",
            "default_reasoning_enabled": true,
            "reasoning_return_mechanism": "reasoning-content"
          },
          "chat_template_config": {}
        },
        "default_parameters": {
          "temperature": 1,
          "top_p": 0.95,
          "top_k": null,
          "frequency_penalty": null,
          "presence_penalty": null,
          "repetition_penalty": null
        },
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
          "id": "72416acd-887a-4940-9ccc-1f22d9e17dbc",
          "name": "Nvidia | nvidia/nemotron-3-ultra-550b-a55b-20260604:free",
          "context_length": 1000000,
          "model": {
            "slug": "nvidia/nemotron-3-ultra-550b-a55b",
            "hf_slug": "nvidia/NVIDIA-Nemotron-3-Ultra-550B-A55B-BF16",
            "updated_at": "2026-06-04T13:45:46.170424+00:00",
            "created_at": "2026-06-04T05:33:28.534306+00:00",
            "hf_updated_at": null,
            "name": "NVIDIA: Nemotron 3 Ultra",
            "short_name": "Nemotron 3 Ultra",
            "author": "nvidia",
            "author_display_name": "Nvidia",
            "author_icon_uri": null,
            "description": "NVIDIA Nemotron 3 Ultra is an open frontier-reasoning and orchestration model from NVIDIA, with 55B active parameters out of 550B total (MoE). Built on a hybrid Transformer-Mamba mixture-of-experts architecture, it supports text input and output with a context window of up to 1M tokens. It is suited for long-running agentic workflows, including agent orchestration, coding agents, deep research, and complex enterprise tasks.\n\nIt is particularly strong at multi-step reasoning and planning, with high-throughput inference designed for high-volume agent pipelines. It is part of the NVIDIA Nemotron family of open models for agentic AI.",
            "model_version_group_id": null,
            "context_length": 1000000,
            "input_modalities": [
              "text"
            ],
            "output_modalities": [
              "text"
            ],
            "has_text_output": true,
            "group": "Other",
            "instruct_type": null,
            "default_system": null,
            "default_stops": [],
            "hidden": false,
            "router": null,
            "warning_message": "For the free endpoint, please do not upload any confidential information or personal data (such as voices or faces of people). Your use is logged for security purposes and to improve NVIDIA products and services. The logged session data for improvement purposes is not linked to your identity or any persistent identifier. For more information about NVIDIA's data processing practices, see [Privacy Policy](https://www.nvidia.com/en-us/about-nvidia/privacy-policy/). By using this free endpoint, you consent to NVIDIA's collection, recording, and use of such information and the [NVIDIA API Trial Terms of Service](https://assets.ngc.nvidia.com/products/api-catalog/legal/NVIDIA%20API%20Trial%20Terms%20of%20Service.pdf)",
            "promotion_message": null,
            "routing_error_message": null,
            "required_attestation_types": [],
            "is_private": false,
            "permaslug": "nvidia/nemotron-3-ultra-550b-a55b-20260604",
            "supports_reasoning": true,
            "reasoning_config": {
              "start_token": "<think>",
              "end_token": "</think>",
              "supports_reasoning_effort": true,
              "supports_reasoning_max_tokens": true,
              "supported_reasoning_efforts": [
                "medium"
              ],
              "default_reasoning_effort": "high",
              "default_reasoning_enabled": true,
              "reasoning_return_mechanism": "reasoning-content"
            },
            "features": {
              "reasoning_config": {
                "start_token": "<think>",
                "end_token": "</think>",
                "supports_reasoning_effort": true,
                "supports_reasoning_max_tokens": true,
                "supported_reasoning_efforts": [
                  "medium"
                ],
                "default_reasoning_effort": "high",
                "default_reasoning_enabled": true,
                "reasoning_return_mechanism": "reasoning-content"
              },
              "chat_template_config": {}
            },
            "default_parameters": {
              "temperature": 1,
              "top_p": 0.95,
              "top_k": null,
              "frequency_penalty": null,
              "presence_penalty": null,
              "repetition_penalty": null
            },
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
          "model_variant_slug": "nvidia/nemotron-3-ultra-550b-a55b:free",
          "model_variant_permaslug": "nvidia/nemotron-3-ultra-550b-a55b-20260604:free",
          "adapter_name": "NvidiaAdapter",
          "provider_name": "Nvidia",
          "provider_info": {
            "name": "Nvidia",
            "displayName": "NVIDIA",
            "slug": "nvidia",
            "baseUrl": "https://integrate.api.nvidia.com/v1",
            "dataPolicy": {
              "training": true,
              "trainingOpenRouter": false,
              "retainsPrompts": true,
              "canPublish": false,
              "termsOfServiceURL": "https://assets.ngc.nvidia.com/products/api-catalog/legal/NVIDIA%20API%20Trial%20Terms%20of%20Service.pdf",
              "privacyPolicyURL": "https://www.nvidia.com/en-us/about-nvidia/privacy-policy/",
              "requiresUserIDs": true
            },
            "headquarters": "US",
            "datacenters": [
              "US"
            ],
            "hasChatCompletions": true,
            "hasCompletions": false,
            "isAbortable": true,
            "moderationRequired": false,
            "requiredAttestationTypes": [],
            "adapterName": "NvidiaAdapter",
            "statusPageUrl": null,
            "byokEnabled": true,
            "isPrivate": false,
            "icon": {
              "url": "https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://www.nvidia.com/en-us/&size=256"
            },
            "sendClientIp": false,
            "pricingStrategy": "openai_chat_completions"
          },
          "provider_permaslug": "nvidia",
          "provider_display_name": "NVIDIA",
          "provider_slug": "nvidia",
          "derived_service_tier": null,
          "provider_model_id": "private/nvidia/nemotron-3-ultra-550b-a55b",
          "quantization": "unknown",
          "variant": "free",
          "is_free": true,
          "can_abort": true,
          "max_prompt_tokens": null,
          "max_completion_tokens": 65536,
          "max_tokens_per_image": null,
          "supported_parameters": [
            "reasoning"
          ],
          "excluded_parameters": [],
          "is_byok": false,
          "moderation_required": false,
          "data_policy": {
            "training": true,
            "trainingOpenRouter": true,
            "retainsPrompts": true,
            "canPublish": false,
            "termsOfServiceURL": "https://assets.ngc.nvidia.com/products/api-catalog/legal/NVIDIA%20API%20Trial%20Terms%20of%20Service.pdf",
            "privacyPolicyURL": "https://www.nvidia.com/en-us/about-nvidia/privacy-policy/",
            "requiresUserIDs": true
          },
          "pricing": {
            "prompt": "0",
            "completion": "0",
            "discount": 0,
            "display_pricing": [
              {
                "kind": "token",
                "sku_label": "Input Price",
                "price": "0",
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
              "price": "0",
              "displayMultiplier": 1000000,
              "unitLabel": "/M tokens"
            }
          ],
          "pricing_json": {
            "openai:prompt_tokens": "0",
            "openai:completion_tokens": "0"
          },
          "pricing_version_id": "7f169f05-a176-4ddc-a3ce-74fc98badc77",
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
          "features": {
            "reasoning_return_mechanism": "reasoning-content",
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
          "allowed_passthrough_parameters": [
            "reasoning_budget"
          ],
          "capacity_tpm": null,
          "created_at": "2026-06-04T05:33:35.709Z",
          "status": -5
        },
        "display_required_attestation_types": [],
        "variant_deprecation_date": null
      }
    ],
    "analytics": {
      "nvidia/nemotron-3-ultra-550b-a55b-20260604:free": {
        "date": "2026-10-09 00:00:00",
        "model_permaslug": "nvidia/nemotron-3-ultra-550b-a55b-20260604",
        "variant": "free",
        "variant_permaslug": "nvidia/nemotron-3-ultra-550b-a55b-20260604:free",
        "count": 54492680,
        "total_completion_tokens": 34528794511,
        "total_prompt_tokens": 7275907123762,
        "total_native_tokens_reasoning": 13556975045,
        "num_media_prompt": 0,
        "num_media_completion": 0,
        "image_output_requests": 0,
        "num_video_prompt": 0,
        "video_output_seconds": 0,
        "rerank_documents": 0,
        "stt_transcript_characters": 0,
        "num_audio_prompt": 0,
        "total_native_tokens_cached": 6217491925440,
        "total_tool_calls": 35953037,
        "requests_with_tool_call_errors": 817398,
        "total_byok_prompt_tokens": 15164704477,
        "total_byok_completion_tokens": 56913555
      }
    },
    "categories": {
      "nvidia/nemotron-3-ultra-550b-a55b-20260604:free": [
        {
          "date": "2026-10-15",
          "model": "nvidia/nemotron-3-ultra-550b-a55b-20260604:free",
          "category": "programming",
          "count": 5040,
          "total_prompt_tokens": 807786368,
          "total_completion_tokens": 2275157,
          "volume": 0,
          "rank": 15
        },
        {
          "date": "2026-10-15",
          "model": "nvidia/nemotron-3-ultra-550b-a55b-20260604:free",
          "category": "science",
          "count": 335,
          "total_prompt_tokens": 27123514,
          "total_completion_tokens": 218449,
          "volume": 0,
          "rank": 41
        }
      ]
    },
    "modality_counts": {
      "text": 15
    },
    "benchmarks": {
      "nvidia/nemotron-3-ultra-550b-a55b-20260604": {
        "aa": {
          "intelligence_index": 22.9,
          "coding_index": 49.3,
          "agentic_index": 20.1
        },
        "da": {
          "default_elo": 1149,
          "elo_by_category": {
            "models-3d": 1132,
            "models-asciiart": 1097,
            "models-codecategories": 1149,
            "models-dataviz": 1142,
            "models-gamedev": 1141,
            "models-svg": 1069,
            "models-uicomponent": 1139,
            "models-website": 1146
          }
        }
      }
    },
    "endpoint_perf": {
      "72416acd-887a-4940-9ccc-1f22d9e17dbc": {
        "p50_latency": 1789.5,
        "p50_throughput": 28
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
