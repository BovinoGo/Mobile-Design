class WorkerDto {
  final String workerId;
  final String userId;
  final String fullName;
  final String email;
  final String companyId;
  final bool canRegisterBovines;
  final bool canUpdateBovineStatus;
  final bool? canSimulateVitalSigns;
  final bool isActive;

  WorkerDto({
    required this.workerId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.companyId,
    required this.canRegisterBovines,
    required this.canUpdateBovineStatus,
    this.canSimulateVitalSigns,
    required this.isActive,
  });

  factory WorkerDto.fromJson(Map<String, dynamic> json) => WorkerDto(
        workerId: (json['workerId'] ?? json['id'] ?? '').toString(),
        userId: (json['userId'] ?? '').toString(),
        fullName: json['fullName'] ?? json['name'] ?? '',
        email: json['email'] ?? '',
        companyId: (json['companyId'] ?? '').toString(),
        canRegisterBovines: json['canRegisterBovines'] ?? false,
        canUpdateBovineStatus: json['canUpdateBovineStatus'] ?? false,
        canSimulateVitalSigns: json['canSimulateVitalSigns'],
        isActive: json['isActive'] ?? true,
      );
}
