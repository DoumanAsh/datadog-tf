# Datadog AWS Integration
# https://docs.datadoghq.com/integrations/guide/aws-terraform-setup/?tab=awscommercialcloud
locals {
  datadog_aws_integration_role = "DatadogIntegrationRole"
}

# Add the actual AWS integration in Datadog
resource "datadog_integration_aws_account" "datadog_aws_integration" {
  account_tags   = ["aws_account:${var.aws_account_id}", "env:${var.environment}"]
  aws_account_id = var.aws_account_id
  aws_partition  = "aws"
  aws_regions {
    include_all = true
  }
  auth_config {
    aws_auth_config_role {
      role_name = local.datadog_aws_integration_role
    }
  }
  resources_config {
    cloud_security_posture_management_collection = false
    extended_collection                          = true
  }
  traces_config {
    xray_services {
    }
  }
  logs_config {
    lambda_forwarder {
    }
  }
  metrics_config {
    namespace_filters {
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.datadog_aws_account_id}:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        "${datadog_integration_aws_account.datadog_aws_integration.auth_config.aws_auth_config_role.external_id}"
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  statement {
    effect = "Allow"
    # Permissions required for Datadog's AWS integration
    # https://docs.datadoghq.com/integrations/amazon-web-services/#aws-iam-permissions
    # https://docs.datadoghq.com/logs/guide/send-aws-services-logs-with-the-datadog-lambda-function
    actions = [
      "account:GetAccountInformation",
      "airflow:GetEnvironment",
      "airflow:ListEnvironments",
      "apigateway:GET",
      "appsync:ListGraphqlApis",
      "autoscaling:Describe*",
      "backup:List*",
      "batch:DescribeJobDefinitions",
      "bcm-data-exports:GetExport",
      "bcm-data-exports:ListExports",
      "budgets:ViewBudget",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrail",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:ListTrails",
      "cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codebuild:BatchGetProjects",
      "codebuild:ListProjects",
      "codedeploy:BatchGet*",
      "codedeploy:List*",
      "cur:DescribeReportDefinitions",
      "directconnect:Describe*",
      "dms:DescribeReplicationInstances",
      "dynamodb:Describe*",
      "dynamodb:List*",
      "ec2:Describe*",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeVerifiedAccessInstanceLoggingConfigurations",
      "ec2:DescribeVpnConnections",
      "ecs:Describe*",
      "ecs:DescribeTaskDefinition",
      "ecs:List*",
      "ecs:ListTaskDefinitionFamilies",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeTags",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticmapreduce:Describe*",
      "elasticmapreduce:List*",
      "es:DescribeElasticsearchDomains",
      "es:ListDomainNames",
      "es:ListTags",
      "events:CreateEventBus",
      "fsx:DescribeFileSystems",
      "fsx:ListTagsForResource",
      "health:DescribeAffectedEntities",
      "health:DescribeEventDetails",
      "health:DescribeEvents",
      "iam:ListAccountAliases",
      "kinesis:Describe*",
      "kinesis:List*",
      "lambda:GetPolicy",
      "lambda:InvokeFunction",
      "lambda:List*",
      "logs:DeleteSubscriptionFilter",
      "logs:DescribeDeliveries",
      "logs:DescribeDeliverySources",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:FilterLogEvents",
      "logs:GetDeliveryDestination",
      "logs:PutSubscriptionFilter",
      "logs:TestMetricFilter",
      "network-firewall:DescribeLoggingConfiguration",
      "network-firewall:ListFirewalls",
      "oam:ListAttachedLinks",
      "oam:ListSinks",
      "organizations:Describe*",
      "organizations:List*",
      "rds:Describe*",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:List*",
      "redshift-serverless:ListNamespaces",
      "redshift:DescribeClusters",
      "redshift:DescribeLoggingStatus",
      "route53:List*",
      "route53:ListQueryLoggingConfigs",
      "route53resolver:ListResolverQueryLogConfigs",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
      "s3:PutBucketNotification",
      "ses:Get*",
      "ses:List*",
      "sns:GetSubscriptionAttributes",
      "sns:List*",
      "sns:Publish",
      "sqs:ListQueues",
      "ssm:GetServiceSetting",
      "ssm:ListCommands",
      "states:DescribeStateMachine",
      "states:ListStateMachines",
      "support:DescribeTrustedAdvisor*",
      "support:RefreshTrustedAdvisorCheck",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "timestream:DescribeEndpoints",
      "wafv2:ListLoggingConfigurations",
      "xray:BatchGetTraces",
      "xray:GetTraceSummaries"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_aws_integration" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration.json
}

resource "aws_iam_role" "datadog_aws_integration" {
  name               = local.datadog_aws_integration_role
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role.json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration.arn
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration_security_audit" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
