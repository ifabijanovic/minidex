"use client";

import ContentCopy from "@mui/icons-material/ContentCopy";
import { Box, IconButton, Tooltip, Typography } from "@mui/material";
import { enqueueSnackbar } from "notistack";

import { uuidPreviewMessages as m } from "@/app/components/messages";

type UuidPreviewProps = {
  id: string | undefined;
};

export function UuidPreview({ id }: UuidPreviewProps) {
  if (!id) {
    return (
      <Typography variant="body2" fontFamily="monospace">
        —
      </Typography>
    );
  }

  const truncatedId = id.slice(-6);

  const handleCopy = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await navigator.clipboard.writeText(id);
      enqueueSnackbar(m.copySuccess, { variant: "success" });
    } catch (err) {
      enqueueSnackbar(m.copyError, { variant: "error" });
    }
  };

  return (
    <Tooltip
      title={
        <Box
          sx={{
            display: "flex",
            flexDirection: { xs: "column", sm: "row" },
            alignItems: { xs: "flex-start", sm: "center" },
            gap: 1,
            maxWidth: { xs: "90vw", sm: "none" },
          }}
        >
          <Typography
            variant="body2"
            fontFamily="monospace"
            sx={{
              wordBreak: "break-all",
              fontSize: { xs: "0.75rem", sm: "0.875rem" },
            }}
          >
            {id}
          </Typography>
          <IconButton
            size="small"
            onClick={handleCopy}
            sx={{ color: "inherit", padding: 0.5, flexShrink: 0 }}
          >
            <ContentCopy fontSize="small" />
          </IconButton>
        </Box>
      }
      arrow
      disableInteractive={false}
      slotProps={{
        tooltip: {
          sx: {
            maxWidth: { xs: "90vw", sm: "none" },
            padding: { xs: 1, sm: 1.5 },
          },
        },
      }}
    >
      <Typography
        variant="body2"
        fontFamily="monospace"
        sx={{ cursor: "pointer" }}
      >
        {truncatedId}
      </Typography>
    </Tooltip>
  );
}
