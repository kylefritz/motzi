import React from "react";
import { reportError } from "../lib/errorReporter";

type ErrorBoundaryProps = {
  children: React.ReactNode;
};

type ErrorBoundaryState = {
  hasError: boolean;
  error?: string;
  stack?: string;
};

export default class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(_error: Error): Partial<ErrorBoundaryState> {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    reportError({
      error_class: error.name || "Error",
      message: error.message || "Unknown error",
      stack: [error.stack || "", errorInfo.componentStack || ""]
        .filter(Boolean)
        .join("\n\nReact component stack:\n"),
      url: typeof location !== "undefined" ? location.pathname : "",
      context: { kind: "react_error_boundary" },
    });
    this.setState({ error: error.message, stack: error.stack?.toString() });
  }

  render() {
    if (this.state.hasError) {
      const { error, stack } = this.state;
      return (
        <>
          <h2>There was an error in this software :(</h2>
          <p className="text-center">Please try again or try back later.</p>
          <div className="mt-5">
            <code>{error}</code>
          </div>
          <div className="mt-2">
            <code className="stack-trace">{stack}</code>
          </div>
        </>
      );
    }

    return this.props.children;
  }
}
