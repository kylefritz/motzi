import styled from "styled-components";

export const Panel = styled.section`
  display: inline-block;
  max-width: 100%;
  padding: 0.85rem 0.95rem;
  border: 1px solid #e3e3e3;
  border-radius: 8px;
  background: #fff;
  box-sizing: border-box;
`;

export const PanelHeader = styled.h4`
  margin: 0 0 0.6rem;
  color: #444;
`;

export const PanelBody = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
`;
