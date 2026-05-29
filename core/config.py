from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import model_validator

class Settings(BaseSettings):
    db_user: str
    db_password: str
    db_host: str
    db_port: int = 5432
    db_name: str
    db_max_connections: int = 5

    # Environment mode
    app_env: str = "development"

    # NCU Portal OAuth
    ncu_oauth_client_id: str = ""
    ncu_oauth_client_secret: str = ""
    ncu_oauth_redirect_uri: str = "http://localhost:8000/auth/callback"
    allowed_redirect_origins: str = "http://localhost:5173,http://localhost:3000,http://localhost:18080"


    # JWT Security
    jwt_secret_key: str = "generate_a_secure_random_string_here"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    @model_validator(mode="after")
    def validate_jwt_secret_key_by_env(self) -> "Settings":
        v = self.jwt_secret_key
        placeholders = {
            "temporary_secret_key_change_me_in_production",
            "generate_a_secure_random_string_here"
        }
        if not v or v.strip() == "":
            raise ValueError(
                "JWT_SECRET_KEY is required and cannot be empty."
            )
        if self.app_env.lower() == "production" and v in placeholders:
            raise ValueError(
                "JWT_SECRET_KEY cannot be set to a placeholder/default value in production."
            )
        return self

    model_config = SettingsConfigDict(env_file='.env', extra='ignore')




settings = Settings()
