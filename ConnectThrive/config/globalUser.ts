export let globalUser = {
  name: "Ravichandra Chandra", // Default fallback if not set
  phone: "+91 9876543210",    // Default fallback if not set
  userId: 1,
  batchId: 1,
};

export const setGlobalUser = (name: string, phone: string, userId?: number, batchId?: number) => {
  globalUser.name = name;
  globalUser.phone = phone;
  if (userId !== undefined) globalUser.userId = userId;
  if (batchId !== undefined) globalUser.batchId = batchId;
};
