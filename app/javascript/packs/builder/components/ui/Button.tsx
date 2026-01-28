import React from "react";
import styled, { css } from "styled-components";

type ButtonVariant = "primary" | "secondary" | "danger";
type ButtonSize = "xs" | "sm" | "md";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
  size?: ButtonSize;
};

const sizeStyles = {
  xs: css`
    min-height: 26px;
    padding: 0.2rem 0.45rem;
    font-size: 0.85rem;
  `,
  sm: css`
    min-height: 30px;
    padding: 0.25rem 0.6rem;
    font-size: 0.95rem;
  `,
  md: css`
    min-height: 36px;
    padding: 0.375rem 0.75rem;
    font-size: 1rem;
  `,
};

const variantStyles = {
  primary: css`
    background: #3f3a80;
    color: #fff;
    border-color: #3f3a80;
    &:hover:not(:disabled) {
      background: #353070;
    }
    &:focus-visible {
      box-shadow: 0 0 0 2px rgba(63, 58, 128, 0.2);
    }
  `,
  secondary: css`
    background: #f8f8f8;
    color: #222;
    border-color: #d0d0d0;
    &:hover:not(:disabled) {
      background: #f1f1f1;
    }
    &:focus-visible {
      box-shadow: 0 0 0 2px rgba(63, 58, 128, 0.12);
    }
  `,
  danger: css`
    background: #fff;
    color: #c7372f;
    border-color: #c7372f;
    &:hover:not(:disabled) {
      background: #c7372f;
      color: #fff;
    }
    &:focus-visible {
      box-shadow: 0 0 0 2px rgba(199, 55, 47, 0.18);
    }
  `,
};

const BaseButton = styled.button<{ $variant: ButtonVariant; $size: ButtonSize }>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  border-radius: 0.25rem;
  border: 1px solid transparent;
  font-weight: 400;
  line-height: 1.5;
  cursor: pointer;
  transition: background-color 120ms ease, border-color 120ms ease,
    color 120ms ease, box-shadow 120ms ease;

  ${({ $size }) => sizeStyles[$size]}
  ${({ $variant }) => variantStyles[$variant]}

  &[data-icon="true"] {
    padding-left: 0.4rem;
    padding-right: 0.4rem;
    min-width: 2rem;
  }

  &:disabled {
    cursor: not-allowed;
    opacity: 0.7;
    box-shadow: none;
  }
`;

export function Button({
  variant = "primary",
  size = "md",
  ...props
}: ButtonProps) {
  return <BaseButton $variant={variant} $size={size} {...props} />;
}
