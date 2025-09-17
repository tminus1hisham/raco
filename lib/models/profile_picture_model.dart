class ProfilePictureModel {
  final String image;

  ProfilePictureModel({required this.image});

  factory ProfilePictureModel.fromJson(Map<String, dynamic> json) {
    return ProfilePictureModel(image: json['image'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'image': image};
  }
}
