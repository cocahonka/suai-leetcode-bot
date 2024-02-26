sealed class AdminState {
  const AdminState();
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminWork extends AdminState {
  const AdminWork();
}

class AdminWaitForCRUD extends AdminState {
  const AdminWaitForCRUD();
}
