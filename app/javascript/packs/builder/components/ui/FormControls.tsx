import styled from "styled-components";

export const ControlSelect = styled.select`
  padding: 0.375rem 0.75rem;
  font-size: 1rem;
  line-height: 1.5;
  color: #212529;
  background: #fff;
  border: 1px solid #cfcfcf;
  border-radius: 0.25rem;
  &:focus {
    outline: none;
    border-color: #3f3a80;
    box-shadow: 0 0 0 2px rgba(63, 58, 128, 0.12);
  }
`;

export const ControlInput = styled.input`
  padding: 0.375rem 0.75rem;
  font-size: 1rem;
  line-height: 1.5;
  color: #212529;
  background: #fff;
  border: 1px solid #cfcfcf;
  border-radius: 0.25rem;
  &:focus {
    outline: none;
    border-color: #3f3a80;
    box-shadow: 0 0 0 2px rgba(63, 58, 128, 0.12);
  }
`;
