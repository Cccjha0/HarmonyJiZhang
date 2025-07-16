export interface Account {
  name: string;
  type: string;
  balance?: number;
}

export interface AccountRecord extends Account {
  id: number;
}