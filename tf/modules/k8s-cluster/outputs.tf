output "control_plane_public_ip" {
  value = aws_instance.control-plane.public_ip
  description = "Public IP of the control plane node"
}
