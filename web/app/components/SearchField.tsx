"use client";

import Clear from "@mui/icons-material/Clear";
import Search from "@mui/icons-material/Search";
import {
  IconButton,
  InputAdornment,
  TextField,
  TextFieldProps,
} from "@mui/material";

type SearchFieldProps = Omit<TextFieldProps, "InputProps"> & {
  value: string;
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
  onClear?: () => void;
  InputProps?: TextFieldProps["InputProps"];
};

export function SearchField({
  value,
  onChange,
  onClear,
  InputProps,
  ...rest
}: SearchFieldProps) {
  const handleClear = () => {
    if (onClear) {
      onClear();
    }
  };

  return (
    <TextField
      {...rest}
      value={value}
      onChange={onChange}
      fullWidth
      sx={{ maxWidth: { xs: "100%", sm: 400 }, ...rest.sx }}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">
            <Search fontSize="small" />
          </InputAdornment>
        ),
        endAdornment: value ? (
          <InputAdornment position="end">
            <IconButton size="small" onClick={handleClear} edge="end">
              <Clear fontSize="small" />
            </IconButton>
          </InputAdornment>
        ) : undefined,
        ...InputProps,
      }}
    />
  );
}
