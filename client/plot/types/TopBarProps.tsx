export type TopBarProps = {
  title?: string;
  showNotifications?: boolean;
  rightElement?: React.ReactNode;
  leftElement?: React.ReactNode;
  middleElement?: React.ReactNode;
  onPressNotifications?: () => void;
  onPressTitle?: () => void;
};