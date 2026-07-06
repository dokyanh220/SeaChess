namespace SeaChess.Application.Services
{
    public class EloCalculator
    {
        private const int PROTECTED_ELO_THRESHOLD = 499;
        private const double TOTAL_MATCH_TIME_MS = 20 * 60 * 1000;

        public static int CalculateWinElo(int winnerElo, int loserElo, double winnerTimeLeftMs)
        {
            int eloDiff = loserElo - winnerElo;

            int baseElo = GetWinBaseElo(eloDiff);

            int timeBonus = GetTimeBonus(winnerTimeLeftMs);

            return baseElo + timeBonus;
        }

        public static int CalculateLoseElo(int loserElo, int winnerElo)
        {
            if (loserElo < PROTECTED_ELO_THRESHOLD) return 0;

            int eloDiff = winnerElo - loserElo;

            int penalty = GetLosePenalty(eloDiff);

            return penalty;
        }

        public static int GetWinBaseElo(int eloDiff)
        {
            return eloDiff switch
            {
                >= 300 => 30,
                >= 100 => 25,
                _ => 20
            };
        }

        public static int GetTimeBonus(double timeLeftMs)
        {
            double minutesLeft = timeLeftMs / 60_00;

            return minutesLeft switch
            {
                >= 10 => 15,
                >= 5 => 7,
                _ => 0
            };
        }

        public static int GetLosePenalty(int eloDiff)
        {
            return eloDiff switch
            {
                <= -300 => -12,  
                <= -100 => -8,  
                <= -50 => -5,  
                _ => -3,  
            };
        }
    }
}