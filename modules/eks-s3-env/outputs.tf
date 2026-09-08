output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "audio_bucket_name" {
  value = module.s3_audio.bucket_id
}

output "cloudfront_domain" {
  value = module.cloudfront_audio.cloudfront_domain_name
}