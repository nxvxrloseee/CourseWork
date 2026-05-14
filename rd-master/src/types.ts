export interface User {
  id: number;
  surname: string;
  name: string;
  patronymic?: string;
  email: string;
  role: string;
  createdAt: string;
}

export interface Ticket {
  id: number;
  title: string;
  description: string;
  category: string;
  status: string;
  customerId: number;
  customerName: string;
  masterId?: number;
  masterName?: string;
  selectedDatetime?: string;
  createdAt: string;
  pricesConfirmedAt?: string;
  mediaUrls: string[];
  services: TicketServiceItem[];
  totalPrice: number;
}

export interface TicketServiceItem {
  id: number;
  serviceId: number;
  serviceName: string;
  price: number;
  quantity: number;
  subtotal: number;
}

export interface StatusHistory {
  status: string;
  changedBy: string;
  description?: string;
  updatedAt: string;
}

export interface ChatMessage {
  id: number;
  ticketId: number;
  senderId: number;
  senderName: string;
  text: string;
  dateSent: string;
  read: boolean;
}

export interface ServiceItem {
  id: number;
  name: string;
  description?: string;
  price: number;
  isActive: boolean;
}

export interface Notification {
  id: number;
  text: string;
  read: boolean;
  ticketId?: number;
  messageId?: number;
  createdAt: string;
}

export interface RevenuePoint {
  date: string;
  revenue: number;
  completed: number;
}

export interface DashboardData {
  totalNew: number;
  totalInProgress: number;
  totalCompleted: number;
  totalCancelled: number;
}

export interface Category {
  id: number;
  name: string;
}
