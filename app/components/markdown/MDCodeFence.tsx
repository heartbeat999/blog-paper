import { Check, Copy, X } from "lucide-react";
import type { DetailedHTMLProps, HTMLAttributes } from "react";
import { useEffect, useRef, useState } from "react";

interface PreProps extends DetailedHTMLProps<
  HTMLAttributes<HTMLPreElement>,
  HTMLPreElement
> {
  children?: React.ReactNode;
}

export function MDCodeFence(props: PreProps) {
  const { children, ...rest } = props;
  const [status, setStatus] = useState<"idle" | "copied" | "failed">("idle");
  const preRef = useRef<HTMLPreElement>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
      }
    };
  }, []);

  // Extract code element and its props
  const codeElement = children as React.ReactElement<{
    className?: string;
  }> | null;
  const className = codeElement?.props?.className || "";

  // Parse language from className (format: "hljs language-xxx")
  const language = className.replace(/hljs language-/, "");

  const flash = (next: "copied" | "failed") => {
    setStatus(next);
    if (timerRef.current) {
      clearTimeout(timerRef.current);
    }
    timerRef.current = setTimeout(() => setStatus("idle"), 2000);
  };

  // 旧浏览器 / 非安全上下文的降级方案
  const fallbackCopy = (text: string) => {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    const ok = document.execCommand("copy");
    document.body.removeChild(textarea);
    return ok;
  };

  const handleCopy = async () => {
    // 从 DOM 读取，语法高亮后的嵌套 span 也能拿到完整文本
    const code = preRef.current?.textContent || "";
    if (!code) {
      flash("failed");
      return;
    }
    try {
      await navigator.clipboard.writeText(code);
      flash("copied");
    } catch {
      // navigator.clipboard 在 http、权限被拒或旧浏览器下会抛错
      flash(fallbackCopy(code) ? "copied" : "failed");
    }
  };

  return (
    <div className="border-ui-line-gray-2 my-4 overflow-hidden rounded-lg border">
      <div className="bg-code-block-bg text-text-gray border-ui-line-gray-2 flex items-center justify-between border-b px-2 py-1 text-sm">
        <span className="px-2 py-1 font-mono">{language}</span>
        <button
          onClick={handleCopy}
          title="复制代码"
          className="hover:bg-hover-bg flex cursor-pointer items-center gap-1.5 rounded px-2 py-1"
        >
          {status === "copied" ? (
            <>
              <Check size={14} style={{ margin: 0 }} />
              <span>已复制</span>
            </>
          ) : status === "failed" ? (
            <>
              <X size={14} style={{ margin: 0 }} />
              <span>复制失败</span>
            </>
          ) : (
            <>
              <Copy size={14} style={{ margin: 0 }} />
              <span>复制</span>
            </>
          )}
        </button>
      </div>
      <pre
        {...rest}
        ref={preRef}
        className="bg-code-block-bg m-0 max-h-70 overflow-y-auto"
      >
        {children}
      </pre>
    </div>
  );
}
