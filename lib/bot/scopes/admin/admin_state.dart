sealed class AdminState {
  const AdminState();
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminWaitForCRUD extends AdminState {
  const AdminWaitForCRUD();
}
