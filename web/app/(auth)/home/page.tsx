"use client";

import { Button, Card, CardContent, Stack, Typography } from "@mui/material";
import Link from "next/link";

const placeholderUser = {
  displayName: "Ash Ketchum",
  email: "ash.ketchum@minidex.dev",
  roleTitle: "Pokémon Master",
};

export default function HomePage() {
  return (
    <Stack spacing={3}>
      <Card>
        <CardContent>
          <Typography variant="h5" gutterBottom>
            Account Overview
          </Typography>
          <Typography variant="body2" color="text.secondary" mb={3}>
            This section will summarize engagement details once the API
            integration is complete.
          </Typography>
          <Stack direction={{ xs: "column", md: "row" }} spacing={3}>
            <UserInfoItem label="Name" value={placeholderUser.displayName} />
            <UserInfoItem label="Email" value={placeholderUser.email} />
            <UserInfoItem label="Role" value={placeholderUser.roleTitle} />
          </Stack>
        </CardContent>
      </Card>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Quick Actions
          </Typography>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Use these shortcuts to navigate once the full experience is ready.
          </Typography>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <Button variant="contained" component={Link} href="/dashboard">
              Go to Home
            </Button>
            <Button variant="outlined" component={Link} href="/account">
              View Profile
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Stack>
  );
}

function UserInfoItem({
  label,
  value,
}: {
  label: string;
  value?: string | null;
}) {
  return (
    <div style={{ minWidth: 200 }}>
      <Typography variant="overline" color="text.secondary">
        {label}
      </Typography>
      <Typography variant="subtitle1" fontWeight={600}>
        {value ?? "—"}
      </Typography>
    </div>
  );
}
