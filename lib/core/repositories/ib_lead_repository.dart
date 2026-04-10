import '../models/ib_lead_model.dart';

abstract class IbLeadRepository {
  Future<IbLeadModel> saveDraft(IbLeadModel lead);
  Future<IbLeadModel> submit(IbLeadModel lead);
  Future<List<IbLeadModel>> getMyLeads(String createdById);
  Future<List<IbLeadModel>> getPendingForBranchHead(String branchHeadId);
  Future<List<IbLeadModel>> getAllForBranchHead(String branchHeadId);
  Future<IbLeadModel?> getById(String id);
  Future<IbLeadModel> approve(String id, {required String branchHeadId, required String branchHeadName});
  Future<IbLeadModel> sendBack(String id, {required String branchHeadId, required String branchHeadName, required String remarks});
}
