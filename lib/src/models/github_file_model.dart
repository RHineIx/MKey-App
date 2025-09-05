class GithubFile {
  final String path;
  final String sha;

  GithubFile({required this.path, required this.sha});

  factory GithubFile.fromJson(Map<String, dynamic> json) {
    return GithubFile(
      path: json['path'],
      sha: json['sha'],
    );
  }
}