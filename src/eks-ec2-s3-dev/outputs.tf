output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "audio_bucket_name" {
  value = aws_s3_bucket.audio.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.audio.domain_name
}
