#------------------------------------------------------------------------------
#  variables.tf
#------------------------------------------------------------------------------

# Account variables

variable "account"              { default = "test 						}
variable "grp"                  { default = "dev"         				}
variable "env"                  { default = "dev1"        				}
variable "key_name"             { default = "ops_key" 					}
variable "project"              { default = "testapp"  					}

variable "log-bucket"           { default = "logs-bucket" 				}

# APP variables

variable "app_version"          { 										}
variable "stackMinSize"         { default = "1"             			}
variable "stackMaxSize"         { default = "4"             			}
variable "stackDesiredSize"     { default = "2"             			}
variable "instance_type"        { default = "m4.large"      			}

# ALB variables

variable "enable_logging"        { default = false           			}
variable "alb_api_is_internal"   { default = false            			}
variable "ipaddress"             { default = []              			}
variable "health_check_path"     { default = "/api/health"}
variable "backend_port"          { default = 8080         	 			}

