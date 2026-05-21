class GlobalUser {
  static String username = '';
  static String mobileNumber = '';
  static int userId = 0;
  static int batchId = 1;

  static void setGlobalUser({
    required String username,
    required String mobileNumber,
    int userId = 0,
    int batchId = 1,
  }) {
    GlobalUser.username = username;
    GlobalUser.mobileNumber = mobileNumber;
    GlobalUser.userId = userId;
    GlobalUser.batchId = batchId;
  }

  static void clear() {
    username = '';
    mobileNumber = '';
    userId = 0;
    batchId = 1;
  }
}
